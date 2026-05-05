from fastapi import APIRouter, File, HTTPException, UploadFile

from app.schemas.recognition import RecognitionResponse

router = APIRouter(prefix="/recognize", tags=["recognition"])


@router.post("", response_model=RecognitionResponse)
async def recognize_shoe(image: UploadFile = File(...)):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Archivo no es imagen")

    # Placeholder until the ML model is integrated.
    return RecognitionResponse(
        candidates=[],
        message="Modelo no integrado. Endpoint listo para conectar.",
    )
