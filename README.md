# renovate-config

The **single source of truth** for cross-cutting
[Renovate](https://docs.renovatebot.com/) decisions and
conventions across all nationalarchives repositories.

This repository works with the
[Renovate GitHub App](https://github.com/apps/renovate)
(hosted by Mend). Each consumer repo extends the shared
presets via `"extends"` in its `renovate.json`.

Repositories that need credentials the app cannot hold —
principally an AWS role assumed via OIDC — run the
[Renovate CLI](#using-the-renovate-cli-instead-of-the-app)
from a reusable workflow in this repository instead. Both
modes read the same presets.

## Onboard repo to Renovate App

1. Remove `.github/dependabot.yml`

2. Add a file `renovate.json` to your repo with the following content:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>nationalarchives/renovate-config"]
}
```

3. Install the Mend **Renovate** app to the repo (requires GitHub admin approval)

4. In repository settings, enable **auto-merge**


## Shared presets

By default, this applies all of the language specific configurations listed below. Each preset is scoped via `matchManagers`, so rules only apply when Renovate detects that manager in the repo — there's no need to opt in per language.

| Preset | Extends as | Description |
|---|---|---|
| `default.json` | `github>nationalarchives/renovate-config` | Base settings (`config:recommended`, dashboard, labels, `platformAutomerge`, OSV vulnerability alerts) **plus** all manager presets listed below |
| `github-actions.json` | `…:github-actions` | GitHub Actions: SHA-pins external actions, skips `nationalarchives/*` internal workflows, 7-day cooldown, automerge all (minor/patch/major) |
| `internal-actions.json` | `…:internal-actions` | Internal `nationalarchives/org-actions` reusable actions: re-enables them (overriding the `nationalarchives/*` skip), SHA-pins, auto-updates semver (minor/patch/major) with **no cooldown** and automerge |
| `python-packages.json` | `…:python-packages` | Python `poetry` and `pip_requirements`: 7-day cooldown, automerge minor/patch, major requires review. Dev packages use `chore` commit type. |
| `pre-commit.json` | `…:pre-commit` | Pre-commit hooks: 7-day cooldown, automerge minor/patch, major requires review |
| `public-terraform-modules.json` | `…:public-terraform-modules` | Public Terraform modules: 7-day cooldown, automerge minor/patch, major PR only |
| `internal-terraform-modules.json` | `…:internal-terraform-modules` | `nationalarchives/immutable-aws-backup/aws` and `nationalarchives/organizations-ous-by-path/aws` Terraform modules: auto-update with no cooldown |
| `aws-ami.json` | `…:aws-ami` | **CLI only.** Pinned EC2 Image Builder AMI versions in Terraform `.tfvars`. Resolves versions from a custom datasource populated by an AWS API call, so it has no effect under the Mend app — see [Using the Renovate CLI instead of the app](#using-the-renovate-cli-instead-of-the-app). Not included in `default.json`; extend it explicitly. |

The individual presets are still exposed (`…:github-actions`,
`…:python-packages`, etc.) so a repo can extend just one if it
needs to override or compose them differently.

## Using the Renovate CLI instead of the app

The Mend app runs on Mend's infrastructure and can only reach
public registries and the GitHub API. Where a repository pins a
version that lives behind a **private AWS API** — for example the
`ImageVersion` tag on an AMI published by EC2 Image Builder —
the app has no way to discover the available versions.

For those repositories, run the **Renovate CLI** from a GitHub
Actions runner instead. The runner assumes an AWS role via OIDC,
queries the AWS API for the available versions, and hands the
result to Renovate as a custom datasource. Everything else is
unchanged: the same presets are resolved from this repository,
and the same pull requests, labels and dashboard are produced.

> **Run one or the other, never both.** If the Mend app is
> installed on a repository that also runs the CLI, every update
> is raised twice. Uninstall the app from the repository (or
> exclude it from the app's repository selection) before enabling
> the scheduled CLI workflow.

### How it works

1. `.github/workflows/run-renovate.yml` in this repository is a
   reusable (`workflow_call`) workflow. Consumer repositories call
   it from a scheduled workflow of their own.
2. The job assumes the configured AWS role using GitHub's OIDC
   provider, so no long-lived AWS keys are stored anywhere.
3. It calls the AWS API, writes one small JSON manifest per image
   and serves them from a short-lived HTTP server on `127.0.0.1`.
   Renovate's `customDatasources` reads from that URL.

   A local file URL is not an option here: Renovate sandboxes
   `file://` datasource reads to its own repository clone
   directory, which is not the Actions workspace, so the read is
   rejected. `http://127.0.0.1` on the runner is the supported
   equivalent and the data never leaves the runner.
4. Renovate runs against the calling repository, signs its commits
   with the bot account's GPG key, and opens pull requests.

### Prerequisites

- A bot GitHub account (`tna-ds-backup` by default) that is a
  member of the organisation with write access to the repository.
- A GPG key on that account whose UID matches a **verified** email
  address on the account, so commits are marked **Verified**.
- A **fine-grained PAT** owned by the bot account, with the
  resource owner set to `nationalarchives`:

  | Scope | Permission | Access |
  |---|---|---|
  | Organization | Members | Read-only |
  | Repository | Metadata | Read-only (automatic) |
  | Repository | Contents | Read and write |
  | Repository | Pull requests | Read and write |
  | Repository | Issues | Read and write |
  | Repository | Commit statuses | Read and write |
  | Repository | Workflows | Read and write |
  | Repository | Dependabot alerts | Read-only |

  `Workflows: read and write` is required because the shared
  presets update GitHub Actions workflow files. A PAT is used
  rather than `GITHUB_TOKEN` so that pull requests raised by
  Renovate trigger status checks.
- An IAM role in the target AWS account trusted by the GitHub OIDC
  provider, with permission to describe the resources being looked
  up (for AMIs, `ec2:DescribeImages`).

### Secrets

The reusable workflow holds no secrets of its own. All three are
read from the **calling** repository's Actions secrets and passed
through explicitly — a reusable workflow cannot see the caller's
secrets otherwise.

| Secret | Contents |
|---|---|
| `RENOVATE_GITHUB_TOKEN` | The bot account's fine-grained PAT |
| `RENOVATE_GPG_PRIVATE_KEY` | ASCII-armoured GPG private key |
| `RENOVATE_GPG_PASSPHRASE` | Passphrase for that key |

The AWS role is assumed via OIDC and needs no secret.

### Workflow inputs

All inputs are optional; the defaults suit National Archives
Digital Services repositories.

| Input | Default | Description |
|---|---|---|
| `git-author-name` | `tna-ds-backup` | Commit author. Must be the GitHub account owning the PAT, or status checks will not run on Renovate's pull requests. |
| `git-author-email` | `s-GitHubDSBackup@nationalarchives.gov.uk` | Commit author email. Must be a verified address on the bot account **and** match the GPG key UID, or commits will not show as Verified. |
| `log-level` | `info` | Set to `debug` when troubleshooting. |
| `enable-ami-lookup` | `false` | Serve EC2 Image Builder AMI versions to Renovate. Required by the `aws-ami` preset. |
| `aws-role-to-assume` | _(none)_ | IAM role ARN assumed via OIDC. Needs `ec2:DescribeImages`. Required when `enable-ami-lookup` is `true`. |
| `aws-region` | `eu-west-2` | Region queried for AMIs. |
| `ami-image-filter` | `*` | Matched against the AMI `Image` tag, to narrow a run to one team's images. Wildcards allowed. |

### AMI version lookup

Set `enable-ami-lookup: true` and extend the `aws-ami` preset to
keep Image Builder AMI version pins up to date.

EC2 Image Builder stamps every build with two tags: `Image`
(stable, e.g. `ds-web-frontend`) and `ImageVersion` (e.g.
`0.0.6-2`, formed from the recipe version and the build number).
The workflow reads those tags, writes one JSON manifest per
image, and serves them on `127.0.0.1:8099` for the duration of
the run. Renovate then treats each image as an ordinary
dependency.

Annotate each pin with the `Image` tag value, on the line above:

```hcl
# renovate: ami=ds-web-frontend
web_frontend_image_version = "0.0.6-2"
```

Versions are ordered with `regex` versioning as
`major.minor.patch-build`, so `0.0.6-3` supersedes `0.0.6-2`, and
`0.0.7-1` supersedes both.

The preset raises **one grouped PR per environment**: pins under
`_vars/dev/` are automerged once checks pass, while
`_vars/staging/` and `_vars/live/` raise review-only PRs. Each
environment gets its own branch, so one can merge without the
others. Override `matchFileNames` in the repo's `renovate.json`
if it uses a different layout.

Grouping means a single failing Terraform plan holds up every
image in that environment. If you would rather have one PR per
image, override `groupName` to `null`.

> Port `8099` and the `<Image tag>.json` filenames are a contract
> between `run-renovate.yml` and `aws-ami.json`. Change one and
> you must change the other.

A caller enabling AMI lookup adds a `with:` block:

```yaml
    uses: nationalarchives/renovate-config/.github/workflows/run-renovate.yml@main
    with:
      enable-ami-lookup: true
      aws-role-to-assume: arn:aws:iam::846769538626:role/GithubOIDCProviderIAMRolePermissions-Role-I80RXHT6O1PL
      ami-image-filter: "ds-*"
```

and extends the preset in `renovate.json`:

```json
{
  "extends": [
    "github>nationalarchives/renovate-config",
    "github>nationalarchives/renovate-config:aws-ami"
  ]
}
```

### Renovate version

The CLI version is pinned in `.renovate-version` in this
repository, and Renovate keeps that file up to date itself. All
consumer repositories therefore move to a new Renovate version
together, rather than drifting independently.

## Onboard repo to Renovate CLI

1. Remove `.github/dependabot.yml`, and make sure the Mend
   Renovate app is **not** installed on the repository.

2. Add `renovate.json`, extending the base presets plus any
   CLI-only preset you need:

   ```json
   {
     "$schema": "https://docs.renovatebot.com/renovate-schema.json",
     "extends": [
       "github>nationalarchives/renovate-config",
       "github>nationalarchives/renovate-config:aws-ami"
     ]
   }
   ```

3. Add the three secrets listed under
   [Secrets](#secrets) to the repository.

4. Add a scheduled caller workflow, e.g.
   `.github/workflows/update-dependencies.yml`:

   ```yaml
   name: Update dependencies

   on:
     workflow_dispatch:
     schedule:
       - cron: "0 2 * * *"

   jobs:
     renovate:
       name: Renovate
       permissions:
         id-token: write
         contents: write
         issues: write
         pull-requests: write
       uses: nationalarchives/renovate-config/.github/workflows/run-renovate.yml@main
       secrets:
         RENOVATE_GITHUB_TOKEN: ${{ secrets.RENOVATE_GITHUB_TOKEN }}
         RENOVATE_GPG_PRIVATE_KEY: ${{ secrets.RENOVATE_GPG_PRIVATE_KEY }}
         RENOVATE_GPG_PASSPHRASE: ${{ secrets.RENOVATE_GPG_PASSPHRASE }}
   ```

   `id-token: write` is required for OIDC and must be granted by
   the caller — permissions cannot be widened by the reusable
   workflow.

5. In repository settings, enable **auto-merge**.

6. Dispatch the workflow manually once and check the resulting
   commits show as **Verified** and authored by the bot account.

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
