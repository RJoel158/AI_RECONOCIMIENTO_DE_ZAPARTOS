from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/zapatos"
    api_title: str = "AI Reconocimiento Zapatos"
    api_version: str = "0.1.0"
    captures_dir: str = "../data/captures"
    product_images_dir: str = "../data/product_images"

    class Config:
        env_prefix = ""
        env_file = ".env"


settings = Settings()
