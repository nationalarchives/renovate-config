# Contributing

## Key conventions

- Config files must be valid JSON conforming to the
  [Renovate configuration options](https://docs.renovatebot.com/configuration-options/).
- Keep presets composable — prefer small, focused presets
  that can be combined via `"extends"`.
- Changes here affect all repositories that consume these
  presets; test changes carefully.

## Implementation workflow

1. **Define the preset** — create or modify the appropriate
   JSON preset file at the repository root. Consult the
   Renovate docs for valid configuration options.
2. **Validate JSON** — run `make validate` to check all
   preset files against the Renovate schema.
3. **Update README** — update `README.md` with any new
   presets or usage changes.

## Verification workflow

1. **Validate config** — run `make validate` to check all
   preset files and `renovate.json` against the Renovate
   schema.
2. **Review downstream impact** — consider which
   repositories consume these presets and how the change
   affects them.
