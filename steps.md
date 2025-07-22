# 5‑Service Tutor Stack — **Hands‑On Manual**

*Target*: spin up **Auth**, **Tutor‑Chat**, **Content**, **Assessment**, **Notifier** services + Traefik gateway locally *and* publish them to Google Cloud Run behind a single domain.

> ⚙️ **Prerequisites**
> • Docker ≥ 25 ⧸ docker‑compose v2  • Python 3.11  • Git  • `gcloud` CLI (logged in, project set)
> • (Optional) OpenAI key in `OPENAI_API_KEY` env‑var
> • Domain you control (e.g. `tutor.dev`) — or use an auto‑generated `run.app` URL for testing.

---

## 0. Clone template & inspect tree

```bash
mkdir tutor‑stack && cd tutor‑stack

# minimal skeleton: one dir per service
git init
git submodule add https://github.com/fastapi-users/fastapi-users services/auth
mkdir -p services/{tutor_chat,content,assessment,notifier}/app
```

```
repo/
├── services/
│   ├── auth/
│   ├── tutor_chat/
│   ├── content/
│   ├── assessment/
│   └── notifier/
└── docker-compose.yaml
```

> **Tip:** treat each service as an *independent* FastAPI app.  Shared Pydantic models live in `libs/common_models/` (install via `pip install -e .`).

---

## 1. Write a **single FastAPI endpoint** per service (MVP)

### `services/content/app/main.py`

```python
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import faiss, numpy as np

app = FastAPI()
model = SentenceTransformer("all-MiniLM-L6-v2")
index = faiss.IndexFlatIP(384)  # cosine‑sim in R^384
texts = []  # naive in‑mem storage

class Doc(BaseModel): text: str

@app.post("/ingest")
async def ingest(doc: Doc):
    emb = model.encode([doc.text])
    index.add(np.array(emb).astype("float32"))
    texts.append(doc.text)
    return {"id": len(texts)-1}

@app.post("/search")
async def search(q: Doc, k: int = 3):
    emb = model.encode([q.text]).astype("float32")
    D, I = index.search(emb, k)
    return {"chunks": [texts[i] for i in I[0]]}
```

*(Other services have equally small `main.py`; copy snippets from the dev stack in Appendix A.)*

---

## 2. Dockerise each service

### `services/content/Dockerfile`

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY app /app
RUN pip install fastapi uvicorn sentence-transformers faiss-cpu
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Repeat for `tutor_chat` (add `dspy`, `openai`), `auth` (add `fastapi_users`, `sqlalchemy`), etc.

---

## 3. Compose the **local stack**

### `docker-compose.yaml`

```yaml
version: "3.9"
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports: ["80:80"]
  content:
    build: ./services/content
    labels:
      - "traefik.http.routers.content.rule=PathPrefix(`/content`)"
  tutor-chat:
    build: ./services/tutor_chat
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    labels:
      - "traefik.http.routers.chat.rule=PathPrefix(`/chat`)"
  auth:
    build: ./services/auth
    labels:
      - "traefik.http.routers.auth.rule=PathPrefix(`/auth`)"
  assessment:
    build: ./services/assessment
    labels:
      - "traefik.http.routers.assess.rule=PathPrefix(`/assessment`)"
  notifier:
    build: ./services/notifier
    labels:
      - "traefik.http.routers.notify.rule=PathPrefix(`/notify`)"
```

### Run & smoke‑test locally

```bash
docker compose up --build -d
curl -X POST localhost/content/ingest -d '{"text":"Newton’s laws ..."}' -H 'Content-Type: application/json'
curl -X POST localhost/tutor_chat/answer -d '{"question":"What is inertia?"}' -H 'Content-Type: application/json'
```

---

## 4. Create a **Google Artifact Registry** & push images

```bash
gcloud artifacts repositories create tutor-repo --repository-format=docker --location=me-central1
for svc in auth tutor_chat content assessment notifier; do
  docker tag $(docker images | grep "${svc}" | awk '{print $3}' | head -1) \
    me-central1-docker.pkg.dev/$(gcloud config get-value project)/tutor-repo/${svc}:v0.1
  docker push me-central1-docker.pkg.dev/$(gcloud config get-value project)/tutor-repo/${svc}:v0.1
done
```

---

## 5. Deploy each container to **Cloud Run**

```bash
for svc in auth tutor_chat content assessment notifier; do
  gcloud run deploy ${svc} \
    --image me-central1-docker.pkg.dev/$(gcloud config get-value project)/tutor-repo/${svc}:v0.1 \
    --platform managed --region me-central1 --allow-unauthenticated
    # add --memory=1Gi --min-instances=0 if desired
  done
```

Take note of the auto‑generated `https://<hash>-<region>.run.app` URL for each.

---

## 6. Create a **Global HTTP Load Balancer** with path routing

```bash
BACKEND_AUTH=$(gcloud run services describe auth --region me-central1 --format="value(status.address.url)")
# Repeat for other services then:

gcloud compute url-maps create tutor-map --default-service=${BACKEND_AUTH}

# Add path rules
gcloud compute url-maps add-path-matcher tutor-map --path-matcher-name=tutor-pm \
  --default-service=${BACKEND_AUTH} \
  --path-rules="/auth/*=${BACKEND_AUTH},/chat/*=$(gcloud run services describe tutor_chat ...)/content/*=$(gcloud run services describe content ...)/assessment/*=$(gcloud run services describe assessment ...)/notify/*=$(gcloud run services describe notifier ...)"

# Reserve external IP & create frontend
gcloud compute addresses create tutor-ip --global
IP=$(gcloud compute addresses describe tutor-ip --global --format="value(address)")

gcloud compute target-http-proxies create tutor-proxy --url-map=tutor-map

gcloud compute forwarding-rules create tutor-fr --global --address=${IP} --ports=80 --target-http-proxy=tutor-proxy
```

Point your DNS `A` record for `api.tutor.dev` to `${IP}`.

*TLS*: enable Google‑managed cert:

```bash
gcloud compute ssl-certificates create tutor-cert --domains api.tutor.dev

gcloud compute target-https-proxies create tutor-https-proxy --url-map=tutor-map --ssl-certificates=tutor-cert

gcloud compute forwarding-rules create tutor-https-fr --global --address=${IP} --ports 443 --target-https-proxy tutor-https-proxy
```

---

## 7. End‑to‑end validation

```bash
curl -X POST https://api.tutor.dev/content/ingest -H 'Authorization: Bearer <your_jwt>' ...
curl   https://api.tutor.dev/chat/answer   -d '{"question":"..."}'
```

If everything is wired, you’ll see the LLM answer referencing chunks you just ingested.

---

## 8. CI/CD in three files (snapshot)

1. `.github/workflows/build.yml` — builds/pushes each service on path change.
2. `infra/main.tf` — Terraform module that pins image digests and sets min/max instances.
3. `scripts/deploy.sh` — wrapper invoking `terraform apply` on successful CI.

*(See Appendix B in the canvas for the exact YAML + Terraform config.)*

---

## 9. Appendices

* **A. Service code snippets** — minimal FastAPI for Auth, Tutor‑Chat (DSPy), Assessment & Notifier.
* **B. GitHub Actions + Terraform templates**.
* **C. Local integration tests with pytest‑docker‑compose.**

Feel free to copy, fork, or cherry‑pick.  Ping me if you get stuck on any step—happy to drill deeper!
