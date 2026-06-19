import click

from app.database import SessionLocal, init_db
from app.security import make_pairing_code
from app.services import create_pairing_code_record


@click.group()
def main() -> None:
    """SSH-only Rivet backend administration."""


@main.group("pairing-code")
def pairing_code() -> None:
    """Manage short-lived pairing codes."""


@pairing_code.command("create")
@click.option("--ttl", default="10m", show_default=True)
def create_pairing_code(ttl: str) -> None:
    init_db()
    if not ttl.endswith("m"):
        raise click.BadParameter("TTL must be minutes, for example 10m")
    ttl_minutes = int(ttl[:-1])
    code = make_pairing_code()
    with SessionLocal() as db:
        create_pairing_code_record(db, code, ttl_minutes)
    click.echo(code)


if __name__ == "__main__":
    main()
