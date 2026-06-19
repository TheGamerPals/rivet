from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    mistral_api_key: str = Field(default="", validation_alias="MISTRAL_API_KEY")
    database_url: str = Field(default="sqlite:///./rivet.sqlite3", validation_alias="DATABASE_URL")
    public_base_url: str = Field(
        default="https://rivetapp.duckdns.org", validation_alias="PUBLIC_BASE_URL"
    )
    timezone: str = Field(default="America/Los_Angeles", validation_alias="TIMEZONE")
    log_level: str = Field(default="INFO", validation_alias="LOG_LEVEL")
    bind_host: str = Field(default="127.0.0.1", validation_alias="RIVET_BIND_HOST")
    bind_port: int = Field(default=8721, validation_alias="RIVET_BIND_PORT")
    model_id: str = Field(default="mistral-large-2512", validation_alias="RIVET_MODEL_ID")


@lru_cache
def get_settings() -> Settings:
    return Settings()
