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

.PHONY: help all assets watch pdf clean

help: ## Show this help
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Inputs:  $(TALKS_DIR)/*.md, $(THEMES_DIR)/*.css, $(TALKS_DIR)/$(ASSETS_DIR)/*"
	@echo "Output:  $(BUILD_DIR)/*.html + $(BUILD_DIR)/$(ASSETS_DIR)/* (PDFs in $(BUILD_DIR)/$(PDF_DIR)/)"

all: $(HTML_FILES) assets ## Build all talks and copy referenced assets

$(BUILD_DIR)/%.html: $(TALKS_DIR)/%.md $(THEMES)
	@mkdir -p $(dir $@)
	$(MARP) --html --theme-set $(THEMES_DIR) --output $@ $<

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

clean: ## Remove the build folder
	rm -rf $(BUILD_DIR)
