#!/bin/bash

# Debug script for curriculum endpoint
echo "🔍 Debugging curriculum endpoint..."

# Start backend in foreground to see logs
echo "Starting backend..."
python main.py &
BACKEND_PID=$!
sleep 5

# Test the curriculum endpoint
echo "Testing curriculum endpoint..."
curl -X GET "http://localhost:8000/content/curriculum" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzYjAyMTdjMi01YjE4LTQzOTItOGVkZS04NTdkY2NlNmYyZTAiLCJhdWQiOlsiZmFzdGFwaS11c2VyczphdXRoIl0sImV4cCI6MTc1Mzk1Nzg5Nn0.clhCEpdHImqnmX0esfYewBh34KHAXmTDvnB1onCms518Ty7r4sUIcSCXqJEgCa-YYbySygZ1rKTC0T7tmtU_W3CV_GhCjY6FEv-Sf3tlH_klPtDvQA2sjHiK6pS8Gqxc_uH5YA3FeA8tHAnuLztDlxsWJ11cXVJiOQmXU_oDoAELlJa_2kmkR4UqKw0-iavCZpYc0sA1cfgjc54WbrVU7gVeBUGM4qV2FZt5lYnrHWdsBU1_CZkdy31kW1eOk1ozVLvTa3SpYAFFYwepbJotTpzHJWN3mViMBtO4W_uuvEqmhGZL3oy7uaYptpZ8lyR2hele5RP5UXYZd9zjSX6Zuw" \
  -v

echo ""
echo "Backend logs:"
kill $BACKEND_PID 