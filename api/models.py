from pydantic import BaseModel


class PeerRequest(BaseModel):
    public_key: str


class PeerResponse(BaseModel):
    public_key: str
    private_ip: str
