# renovate-config

The **single source of truth** for cross-cutting
[Renovate](https://docs.renovatebot.com/) decisions and
conventions across all nationalarchives repositories.

This repository works with the
[Renovate GitHub App](https://github.com/apps/renovate)
(hosted by Mend). Each consumer repo extends the shared
presets via `"extends"` in its `renovate.json`.

## Onboard repo to Renovate

1. Remove `.github/dependabot.yml`

2. Add a file `renovate.json` to your repo with the following content:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>nationalarchives/renovate-config"]
}
```


3. Install the Mend **Renovate** app to the repo (may require GitHub admin approval)


## Shared presets

By default, this applies all of the language specific configurations listed below. Each preset is scoped via `matchManagers`, so rules only apply when Renovate detects that manager in the repo — there's no need to opt in per language.

| Preset | Extends as | Description |
|---|---|---|
| `default.json` | `github>nationalarchives/renovate-config` | Base settings (`config:recommended`, dashboard, labels, `platformAutomerge`, OSV vulnerability alerts) **plus** all manager presets listed below |
| `github-actions.json` | `…:github-actions` | GitHub Actions: SHA-pins external actions, skips `nationalarchives/*` internal workflows, 7-day cooldown, weekly Monday schedule, automerge all (minor/patch/major) |
| `python-packages.json` | `…:python-packages` | Python `pip_requirements`: 7-day cooldown, weekly, automerge minor/patch, major requires review. Dev packages use `chore` commit type. |
| `pre-commit.json` | `…:pre-commit` | Pre-commit hooks: 7-day cooldown, weekly, automerge minor/patch, major requires review |
| `public-terraform-modules.json` | `…:public-terraform-modules` | Public Terraform modules: 7-day cooldown, automerge minor/patch, major PR only |
| `internal-terraform-modules.json` | `…:internal-terraform-modules` | `nationalarchives/immutable-aws-backup/aws` and `nationalarchives/organizations-ous-by-path/aws` Terraform modules: auto-update with no cooldown |

The individual presets are still exposed (`…:github-actions`,
`…:python-packages`, etc.) so a repo can extend just one if it
needs to override or compose them differently.

## Opting out or overriding

Because every manager preset is pulled in transitively from
`default.json`, consumer repos sometimes need to disable or
replace one. Renovate supports this via
[`ignorePresets`](https://docs.renovatebot.com/configuration-options/#ignorepresets)
and `packageRules` overrides.

### Opt out of a single preset

List the exact preset string used by `default.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>nationalarchives/renovate-config"],
  "ignorePresets": [
    "github>nationalarchives/renovate-config:python-packages"
  ]
}
```

The named preset is stripped from the resolved config before
rules are applied.

### Override behaviour in place

`packageRules` declared in the repo's `renovate.json` are
evaluated **after** those pulled in via `extends`, so later
rules override earlier ones for the same match. Use this for
small tweaks (e.g. disabling one package, forcing automerge
for another):

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>nationalarchives/renovate-config"],
  "packageRules": [
    {
      "matchManagers": ["terraform"],
      "matchPackageNames": ["hashicorp/aws"],
      "enabled": false
    }
  ]
}
```

### Replace a preset with a custom one

Combine `ignorePresets` with an additional `extends` entry:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>nationalarchives/renovate-config",
    "github>nationalarchives/some-other-repo:python-packages-strict"
  ],
  "ignorePresets": [
    "github>nationalarchives/renovate-config:python-packages"
  ]
}
```

## PR Validation

`.github/workflows/ci.yml` runs on every PR:

- **Validate** — runs `renovate-config-validator --strict
  --no-global` on each preset JSON file

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for implementation
and verification workflows.
