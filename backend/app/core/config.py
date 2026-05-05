from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg2://postgres:postgres@localhost:5432/zapatos"
    api_title: str = "AI Reconocimiento Zapatos"
    api_version: str = "0.1.0"

    class Config:
        env_prefix = ""
        env_file = ".env"


settings = Settings()
