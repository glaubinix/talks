TALKS_DIR  := talks
ASSETS_DIR := assets
THEMES_DIR := themes
BUILD_DIR  := build
PDF_DIR    := pdf

MD_FILES   := $(wildcard $(TALKS_DIR)/*.md)
HTML_FILES := $(patsubst $(TALKS_DIR)/%.md,$(BUILD_DIR)/%.html,$(MD_FILES))
PDF_FILES  := $(patsubst $(TALKS_DIR)/%.md,$(BUILD_DIR)/$(PDF_DIR)/%.pdf,$(MD_FILES))
THEMES     := $(wildcard $(THEMES_DIR)/*.css)

MARP := npx --yes @marp-team/marp-cli@latest

.PHONY: help all assets watch pdf index serve clean

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Inputs:  $(TALKS_DIR)/*.md, $(THEMES_DIR)/*.css, $(TALKS_DIR)/$(ASSETS_DIR)/*"
	@echo "Output:  $(BUILD_DIR)/*.html + $(BUILD_DIR)/$(ASSETS_DIR)/* (PDFs in $(BUILD_DIR)/$(PDF_DIR)/)"

all: $(HTML_FILES) assets index ## Build all talks, copy referenced assets, generate index

$(BUILD_DIR)/%.html: $(TALKS_DIR)/%.md $(THEMES)
	@mkdir -p $(dir $@)
	$(MARP) --html --theme-set $(THEMES_DIR) --output $@ $<

index: $(BUILD_DIR)/index.html ## Generate build/index.html listing all talks

$(BUILD_DIR)/index.html: $(MD_FILES)
	@mkdir -p $(BUILD_DIR)
	@{ \
	  echo '<!DOCTYPE html>'; \
	  echo '<html lang="en"><head><meta charset="utf-8"><title>Talks</title>'; \
	  echo '<style>body{font-family:system-ui,sans-serif;max-width:40rem;margin:2rem auto;padding:0 1rem;line-height:1.6}h1{margin-bottom:1.5rem}ul{list-style:none;padding:0}li{margin:.5rem 0}time{color:#666;margin-right:.75rem;font-variant-numeric:tabular-nums}</style>'; \
	  echo '</head><body><h1>Talks</h1><ul>'; \
	  for md in $(MD_FILES); do \
	    name=$$(basename "$$md" .md); \
	    title=$$(awk '/^# / { sub(/^# /, ""); print; exit }' "$$md"); \
	    if [ -z "$$title" ]; then title="$$name"; fi; \
	    date=$$(echo "$$name" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || true); \
	    echo "<li><time>$$date</time><a href=\"$$name.html\">$$title</a></li>"; \
	  done | sort -r; \
	  echo '</ul></body></html>'; \
	} > $@

assets: $(MD_FILES) ## Copy assets referenced by talks into the build folder
	@mkdir -p $(BUILD_DIR)/$(ASSETS_DIR)
	@grep -hoE '$(ASSETS_DIR)/[A-Za-z0-9._/-]+' $(MD_FILES) \
	  | sort -u \
	  | while read -r asset; do \
	      mkdir -p "$(BUILD_DIR)/$$(dirname "$$asset")"; \
	      cp "$(TALKS_DIR)/$$asset" "$(BUILD_DIR)/$$asset"; \
	    done

watch: ## Serve talks at http://localhost:8080/ with live reload on save
	$(MARP) --html --theme-set $(THEMES_DIR) --server $(TALKS_DIR)

pdf: $(PDF_FILES) ## Build PDF versions of all talks into build/pdf/

$(BUILD_DIR)/$(PDF_DIR)/%.pdf: $(TALKS_DIR)/%.md $(THEMES)
	@mkdir -p $(dir $@)
	$(MARP) --pdf --allow-local-files --html --theme-set $(THEMES_DIR) --output $@ $<

serve: ## Serve the build folder at http://localhost:8888/
	cd $(BUILD_DIR) && php -S 0.0.0.0:8888

clean: ## Remove the build folder
	rm -rf $(BUILD_DIR)
