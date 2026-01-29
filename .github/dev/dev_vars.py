"""Generate dev.tfvars for workspace tests."""

from pathlib import Path

import typer

app = typer.Typer()

WORKSPACE_DIR = Path(__file__).parent.parent.parent / "tests" / "workspace_aws_examples"
DEV_TFVARS = WORKSPACE_DIR / "dev.tfvars"

_project_ids = """\
project_ids = {
  encryption                  = "PROJECT_ID"
  encryption_private_endpoint = "PROJECT_ID"
  backup_export               = "PROJECT_ID"
}
"""


@app.command()
def aws(
    org_id: str = typer.Option(..., envvar="MONGODB_ATLAS_ORG_ID"),
    project_id: str = typer.Option("", envvar="MONGODB_ATLAS_PROJECT_ID"),
) -> None:
    """Generate dev.tfvars for AWS workspace tests."""
    WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    lines = [f'org_id = "{org_id}"']
    if project_id:
        lines.append(_project_ids.replace("PROJECT_ID", project_id))
    content = "\n".join(lines) + "\n"
    DEV_TFVARS.write_text(content)
    typer.echo(f"Generated {DEV_TFVARS}")


@app.command()
def tfrc(plugin_dir: str) -> None:
    """Print dev.tfrc content for provider dev_overrides."""
    content = f'''provider_installation {{
  dev_overrides {{
    "mongodb/mongodbatlas" = "{plugin_dir}"
  }}
  direct {{}}
}}
'''
    print(content, end="")


if __name__ == "__main__":
    app()
