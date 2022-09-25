
import os

import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import OAuth2PasswordBearer

from database import create_db, create_user, get_new_private_ip
from models import PeerRequest, PeerResponse
from utils import add_user_to_vpn, get_vpn_public_key

api = FastAPI()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


def api_key_auth(api_key: str = Depends(oauth2_scheme)):
    if api_key != os.getenv("API_KEY"):
        raise HTTPException(
            status_code=401,
            detail="Forbidden"
        )


@api.get("/health")
def health():
    return {"status": "healthy"}


@api.post("/user", response_model=PeerResponse, dependencies=[Depends(api_key_auth)])
def user(peer: PeerRequest):
    new_private_ip = get_new_private_ip()
    try:
        create_user(new_private_ip)
    except:
        return {"error": "Could not create a new user to VPN!"}
    try:
        add_user_to_vpn(peer.public_key, new_private_ip)
    except:
        return {"error": "Given public key is invalid."}
    return PeerResponse(
        public_key=get_vpn_public_key(),
        private_ip=new_private_ip
    )


if __name__ == "__main__":
    create_db()
    uvicorn.run(
        "main:api",
        host="0.0.0.0",
        port=8000,
        log_level="info",
        reload=True,
    )
