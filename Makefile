PREFIX     ?= $(HOME)/.local
INSTALL_DIR = $(PREFIX)/share/lazy-snapper
BIN_DIR     = $(PREFIX)/bin

SHELL_SOURCES := bin/lazy-snapper lib/core.sh lib/snapper.sh lib/ui.sh lib/utils.sh \
                 install uninstall tests/test_core.sh tests/test_snapper.sh

.PHONY: all install uninstall test lint clean help

all: help

## install: Install lazy-snapper to $(PREFIX)
install:
	@bash install

## uninstall: Remove lazy-snapper from $(PREFIX)
uninstall:
	@bash uninstall

## test: Run the test suite
test:
	@echo "Running tests..."
	@bash tests/test_core.sh
	@bash tests/test_snapper.sh
	@echo ""
	@echo "All tests passed."

## lint: Run shellcheck on all shell sources
lint:
	@echo "Running shellcheck..."
	@shellcheck --shell=bash --enable=all \
		--exclude=SC2034,SC1091,SC2154,SC2312 \
		$(SHELL_SOURCES)
	@echo "shellcheck passed."

## clean: Remove generated/temp files
clean:
	@find . -name '*.swp' -delete
	@find . -name '*~' -delete
	@echo "Clean."

## help: Show this help
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
