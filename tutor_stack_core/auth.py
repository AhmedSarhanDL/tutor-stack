"""JWT verification helper for Tutor Stack services"""

import os
import jwt
from fastapi import Depends, HTTPException, status, Request
from typing import Annotated, Dict, Any

ALG = os.getenv("JWT_ALG", "RS256")
PUB = os.getenv("JWT_PUBLIC_KEY", "change_me")  # HS256 -> same secret


def _decode(tok: str) -> Dict[str, Any]:
    """Decode and validate JWT token"""
    try:
        return jwt.decode(
            tok, 
            PUB, 
            algorithms=[ALG], 
            options={"require": ["exp", "sub"]}
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Token expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Bad token"
        )


def current_active_user(req: Request) -> Dict[str, Any]:
    """Get current active user from JWT token"""
    hdr = req.headers.get("Authorization", "")
    if not hdr.lower().startswith("bearer "):  # fast fail
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Missing bearer token"
        )
    
    payload = _decode(hdr.split()[1])
    if not payload.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Inactive user"
        )
    return payload


# Type alias for dependency injection
User = Annotated[Dict[str, Any], Depends(current_active_user)] 