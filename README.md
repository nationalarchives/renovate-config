# renovate-config

The **single source of truth** for cross-cutting
[Renovate](https://docs.renovatebot.com/) decisions and
conventions across all nationalarchives repositories.

This repository works with the
[Renovate GitHub App](https://github.com/apps/renovate)
(hosted by Mend). Each consumer repo extends the shared
presets via `"extends"` in its `renovate.json`.

## Quick start

Extend the shared preset in your repo's `renovate.json`:

```json
{
  "extends": ["github>nationalarchives/renovate-config"]
}
```

Then add the presets that match your dependency types.

## Shared presets

| Preset | Extends as | Description |
|---|---|---|
| `default.json` | `github>nationalarchives/renovate-config` | Base settings: `config:recommended`, dashboard, labels, `platformAutomerge`, OSV vulnerability alerts |
| `github-actions.json` | `…:github-actions` | GitHub Actions: SHA-pins external actions, skips `nationalarchives/*` internal workflows, 7-day cooldown, weekly Monday schedule, automerge all (minor/patch/major) |
| `python-packages.json` | `…:python-packages` | Python `pip_requirements`: 7-day cooldown, weekly, automerge minor/patch, major requires review. Dev packages use `chore` commit type. |
| `terraform-providers.json` | `…:terraform-providers` | Terraform providers: 7-day cooldown, weekly, automerge minor/patch, major requires review |
| `internal-terraform-modules.json` | `…:internal-terraform-modules` | `nationalarchives/immutable-aws-backup/aws` and `nationalarchives/organizations-ous-by-path/aws` Terraform modules: auto-update with no cooldown |
| `pre-commit.json` | `…:pre-commit` | Pre-commit hooks: 7-day cooldown, weekly, automerge minor/patch, major requires review |

## Consumer examples

### Repo using GitHub Actions + Python

```json
{
  "extends": [
    "github>nationalarchives/renovate-config",
    "github>nationalarchives/renovate-config:github-actions",
    "github>nationalarchives/renovate-config:python-packages"
  ]
}
```

### Repo using internal Terraform modules

```json
{
  "extends": [
    "github>nationalarchives/renovate-config",
    "github>nationalarchives/renovate-config:github-actions",
    "github>nationalarchives/renovate-config:python-packages",
    "github>nationalarchives/renovate-config:internal-terraform-modules"
  ]
}
```

### Repo using Terraform providers

```json
{
  "extends": [
    "github>nationalarchives/renovate-config",
    "github>nationalarchives/renovate-config:terraform-providers"
  ]
}
```

## CI

`.github/workflows/ci.yml` runs on every PR:

- **Validate** — runs `renovate-config-validator --strict
  --no-global` on each preset JSON file

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for implementation
and verification workflows.
