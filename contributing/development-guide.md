# Contributing to terraform-mongodbatlas-atlas-aws

Quick guide for contributing to this Terraform module.

## Quick Start

```bash
# Install required tools (macOS with Homebrew)
brew install just terraform tflint terraform-docs uv pre-commit

# Or use mise for automated tool management
mise install

# Clone and setup
git clone <repo-url>
cd terraform-mongodbatlas-atlas-aws

# Install git hooks (optional but recommended)
pre-commit install
pre-commit install --hook-type pre-push

# Verify installation
just

# Before committing (runs automatically if hooks installed)
just pre-commit
```

**Tools**: [just](https://just.systems/) | [Terraform](https://www.terraform.io/) | [TFLint](https://github.com/terraform-linters/tflint) | [terraform-docs](https://terraform-docs.io/) | [uv](https://docs.astral.sh/uv/) | [pre-commit](https://pre-commit.com/) | [mise](https://mise.jdx.dev/)

## Prerequisites

- macOS with [Homebrew](https://brew.sh/) or Linux
- [Git](https://git-scm.com/) for version control
- [uv](https://docs.astral.sh/uv/) Python installer (for doc generation)
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) Account (for testing, optional)

## Development Workflow

```bash
# Daily workflow
just fmt                      # Format Terraform code
just lint                     # Run Terraform linters
just py-fmt                   # Format Python code
just py-check                 # Lint Python code
just py-test                  # Run Python unit tests
just pre-commit               # Run fast checks (fmt, validate, lint, check-docs, py-check)
just pre-push                 # Run slower checks (pre-commit + unit-plan-tests, py-test)

# Documentation
just docs                     # Generate all docs
just check-docs               # Verify docs are up-to-date (CI mode)

# Terraform file generation
just tf-gen --config gen.yaml     # Generate all targets from config
just tf-gen --config gen.yaml --dry-run  # Preview without writing

# Testing (see test-guide.md for full details)
just unit-plan-tests          # Plan-only tests (no credentials)
just test-compat              # Terraform version compatibility
```

Run `just --list` for all commands.

## Git Hooks

Git hooks automate checks before commits and pushes. Install with [pre-commit](https://pre-commit.com/):

```bash
pre-commit install                    # Install pre-commit hook
pre-commit install --hook-type pre-push  # Install pre-push hook
```

| Hook | Runs | Command |
|------|------|---------|
| pre-commit | Before each commit | `just pre-commit` (fmt, validate, lint, docs, py-check) |
| pre-push | Before each push | `just pre-push` (pre-commit + unit-plan-tests, py-test) |

To skip hooks temporarily: `git commit --no-verify` or `git push --no-verify`.

## CI/CD Workflows

### Workflow Summary

| Workflow | Triggers | Just Targets | Provider |
|----------|----------|--------------|----------|
| `code-health.yml` | PR, push main, nightly | `pre-commit`, `unit-plan-tests`, `test-compat`, `plan-snapshot-test` | master |
| `dev-integration-test.yml` | PR/push (tf changes), nightly | `dev-integration-test` | master |
| `pre-release-tests.yml` | manual | `tftest-all`, `apply-examples`, `destroy-examples` | registry (or custom branch) |
| `release.yml` | manual | `check-release-ready`, `release-commit`, `generate-release-body` | N/A |

### Provider Testing Policy

- **PR/push/nightly**: Uses provider `master` branch via `TF_CLI_CONFIG` dev_overrides
- **Pre-release**: Uses latest published registry provider by default; optionally specify `provider_branch` input to test with a specific provider branch

### Required Secrets

| Secret | Description |
|--------|-------------|
| `MONGODB_ATLAS_ORG_ID` | Atlas organization ID for tests |
| `MONGODB_ATLAS_CLIENT_ID` | Service account client ID |
| `MONGODB_ATLAS_CLIENT_SECRET` | Service account client secret |
| `MONGODB_ATLAS_BASE_URL` | Atlas API base URL (cloud-dev) |
| `AWS_ACCESS_KEY_ID` | AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `AWS_REGION` | AWS region |

## Testing

See [test-guide.md](./test-guide.md) for detailed testing documentation including:
- Authentication setup
- Unit and integration tests
- Version compatibility testing
- Plan snapshot tests with workspace tooling

## Documentation

Documentation is auto-generated from Terraform source files and configuration. Run `just docs` before committing to regenerate all docs.

### Documentation Generation Workflow

The `just docs` command runs:

1. Format Terraform files (`terraform fmt`)
2. Generate terraform-docs sections (Requirements, Providers, Resources, Variables, Outputs)
3. Generate grouped Inputs section from `variable_*.tf` files
4. Generate root README.md TOC and example tables
5. Generate example README.md and versions.tf files

### Regenerating Documentation Locally

```bash
# Regenerate all documentation
just docs

# Verify documentation is up-to-date (for CI/pre-push)
just check-docs
```

If `just check-docs` fails, run `just docs` locally and commit the changes.

## Release Process (Maintainers)

Releases are automated via the `release.yml` GitHub Actions workflow. The workflow uses a 2-commit + revert strategy to keep tags reachable from main branch history.

### Version Placeholder

During development, `module_version` in `versions.tf` is set to `"local"`. The release process replaces this with the actual version number.

### Creating a Release (GitHub Actions)

Trigger the `Release` workflow from GitHub Actions with the version (e.g., `v1.0.0`).

**What happens**:
1. Pre-release validation (version format, changelog, docs)
2. Changelog commit: Updates `CHANGELOG.md` with version header
3. Release commit: Updates `module_version`, regenerates docs with absolute links, registry source URLs
4. Tag created and pushed
5. Release commit reverted on main (restores `"local"` version)
6. GitHub release created with changelog content

### Manual Release (Local)

```bash
just check-release-ready v1.0.0   # Validate prerequisites
just release-commit v1.0.0        # Create changelog + release commits, tag
git push origin v1.0.0            # Push tag
just release-post-push            # Revert release commit
git push origin main              # Push main with changelog + revert
```

## Submitting Changes

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and verify
just pre-commit

# Commit and push
git add .
git commit -m "feat: your feature description"
git push origin feature/your-feature-name
```

## Getting Help

- Check [Issues](../../../issues) for similar problems
- Create new issue with output from `just pre-commit` if needed
- See [Terraform docs](https://www.terraform.io/docs) and [MongoDB Atlas Provider docs](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs)
