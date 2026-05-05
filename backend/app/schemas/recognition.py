from pydantic import BaseModel


class RecognitionCandidate(BaseModel):
    sku: str
    score: float


class RecognitionResponse(BaseModel):
    candidates: list[RecognitionCandidate]
    message: str
