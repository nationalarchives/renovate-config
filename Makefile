PRESET_FILES := $(filter-out renovate.json, $(wildcard *.json))

.PHONY: validate

validate:
	@echo "=== Validating preset files ==="
	@for f in $(PRESET_FILES); do \
		echo "  $$f"; \
		npx --package renovate -- renovate-config-validator --strict --no-global "$$f"; \
	done
	@echo "=== Validating repo config ==="
	@echo "  renovate.json"
	@npx --package renovate -- renovate-config-validator
