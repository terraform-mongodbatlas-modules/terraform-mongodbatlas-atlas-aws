"""Generate dev.tfvars for workspace tests."""

from pathlib import Path

import typer

app = typer.Typer()

WORKSPACE_DIR = Path(__file__).parent.parent.parent / "tests" / "workspace_aws_examples"
DEV_TFVARS = WORKSPACE_DIR / "dev.tfvars"

_project_ids = """\
project_ids = {
  encryption                     = "PROJECT_ID"
  encryption_private_endpoint    = "PROJECT_ID"
  backup_export                  = "PROJECT_ID"
  log_integration                = "PROJECT_ID"
  privatelink                    = "PROJECT_ID"
  privatelink_byoe               = "PROJECT_ID"
  privatelink_multi_region       = "PROJECT_ID"
  privatelink_cross_region       = "PROJECT_ID"
  privatelink_byoe_cross_region  = "PROJECT_ID"
  byo_role                       = "PROJECT_ID"
}
"""


@app.command()
def aws(
    env: str,
    owner: str,
    org_id: str = typer.Option(..., envvar="MONGODB_ATLAS_ORG_ID"),
    project_id: str = typer.Option("", envvar="MONGODB_ATLAS_PROJECT_ID"),
) -> None:
    """Generate dev.tfvars for AWS workspace tests."""
    if not env:
        raise typer.BadParameter("env must not be empty")
    if not owner:
        raise typer.BadParameter("owner must not be empty (CI passes vars.MONGODB_OWNER)")
    WORKSPACE_DIR.mkdir(parents=True, exist_ok=True)
    lines = [
        f'org_id = "{org_id}"',
        f'aws_tags = {{\n  "mongodb-env"   = "{env}"\n  "mongodb-owner" = "{owner}"\n}}',
    ]
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
