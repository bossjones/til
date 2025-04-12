set shell := ["zsh", "-cu"]

# just manual: https://github.com/casey/just/#readme

# Ignore the .env file that is only used by the web service
set dotenv-load := false

CURRENT_DIR := "$(pwd)"

base64_cmd := if "{{os()}}" == "macos" { "base64 -w 0 -i cert.pem -o ca.pem" } else { "base64 -w 0 -i cert.pem > ca.pem" }
grep_cmd := if "{{os()}}" =~ "macos" { "ggrep" } else { "grep" }

# Variables
PYTHON := "uv run python"
UV_RUN := "uv run"

# Recipes
# Install the virtual environment and install the pre-commit hooks
install:
    @echo "🚀 Creating virtual environment using uv"
    uv sync
    uv tool upgrade pyright
    uv run pre-commit install

# Run code quality tools.
check:
    @echo "🚀 Checking lock file consistency with 'pyproject.toml'"
    uv lock --locked
    @echo "🚀 Linting code: Running pre-commit"
    uv run pre-commit run -a

# Test the code with pytest
test:
    @echo "🚀 Testing code: Running pytest"
    {{PYTHON}} -m pytest --cov --cov-config=pyproject.toml --cov-report=xml

# Build wheel file
build: clean-build
    @echo "🚀 Creating wheel file"
    uvx --from build pyproject-build --installer uv

# Clean build artifacts
clean-build:
    @echo "🚀 Removing build artifacts"
    {{PYTHON}} -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

# Test if documentation can be built without warnings or errors
docs-test:
    uv run mkdocs build -s

# Build and serve the documentation
docs:
    uv run mkdocs serve

help:
    @just --list

default: help


# Print the current operating system
info:
		print "OS: {{os()}}"

# Display system information
system-info:
	@echo "CPU architecture: {{ arch() }}"
	@echo "Operating system type: {{ os_family() }}"
	@echo "Operating system: {{ os() }}"

# verify python is running under pyenv
which-python:
		python -c "import sys;print(sys.executable)"

# Run all pre-commit hooks on all files
pre-commit-run-all:
	uv run pre-commit run --all-files

# Install pre-commit hooks
pre-commit-install:
	uv run pre-commit install

# Display the dependency tree of the project
pipdep-tree:
	pipdeptree --python .venv/bin/python3

# install uv tools globally
uv-tool-install:
	uv install invoke
	uv install pipdeptree
	uv install click

# Format Markdown files using pre-commit
fmt-markdown-pre-commit:
	git ls-files '*.md' | xargs uv run pre-commit run --files

# Serve the documentation locally for preview
docs_preview:
    uv run mkdocs serve

# Build the documentation
docs_build:
    uv run mkdocs build

# Deploy the documentation to GitHub Pages
docs_deploy:
    uv run mkdocs gh-deploy --clean

# Checkout main branch and pull latest changes
gco:
    gco main
    git pull --rebase

# install aicommits and configure it
init-aicommits:
	npm install -g aicommits
	aicommits config set OPENAI_KEY=$OCO_OPENAI_API_KEY type=conventional model=gpt-4o max-length=100
	aicommits hook install

# Run aider
aider:
	uv run aider -c .aider.conf.yml --aiderignore .aiderignore

aider-o1-preview:
	uv run aider -c .aider.conf.yml --aiderignore .aiderignore --o1-preview --architect --edit-format whole --model o1-mini --no-stream

aider-sonnet:
	uv run aider -c .aider.conf.yml --aiderignore .aiderignore --sonnet --architect --map-tokens 2048 --cache-prompts --edit-format diff

# Run aider with Claude
aider-claude:
	uv run aider -c .aider.conf.yml --aiderignore .aiderignore --model 'anthropic/claude-3-5-sonnet-20241022'


# SOURCE: https://github.com/RobertCraigie/prisma-client-py/blob/da53c4280756f1a9bddc3407aa3b5f296aa8cc10/Makefile#L77
# Remove all generated files and caches
clean:
	#!/bin/bash
	rm -rf .cache
	rm -rf `find . -name __pycache__`
	rm -rf .tests_cache
	rm -rf .mypy_cache
	rm -rf htmlcov
	rm -rf *.egg-info
	rm -f .coverage
	rm -f .coverage.*
	rm -rf build
	rm -rf dist
	rm -f coverage.xml



# Lint markdown files
uv_lint_markdown:
    {{UV_RUN}} pymarkdownlnt --disable-rules=MD013,MD034 scan README.md

# Serve documentation locally
uv_serve_docs:
    {{UV_RUN}} mkdocs serve

uv_fmt:
    {{UV_RUN}} pre-commit run --all-files

# Deploy documentation to GitHub Pages
uv_gh_deploy:
    {{UV_RUN}} mkdocs gh-deploy --force --message '[skip ci] Docs updates'

# Create site directory
uv_mkdir_site:
    mkdir site

# Deploy documentation
uv_deploy_docs:
    just uv_mkdir_site
    just uv_gh_deploy

# Add bespoke adobe concepts to cursor context
add-cursor-context:
	mkdir -p democracy_exe/vendored || true
	gh repo clone universityofprofessorex/cerebro-bot democracy_exe/vendored/cerebro-bot || true && cd democracy_exe/vendored/cerebro-bot && git checkout feature-discord-utils && cd ../../..
	gh repo clone bossjones/sandbox_agent democracy_exe/vendored/sandbox_agent || true
	gh repo clone langchain-ai/retrieval-agent-template democracy_exe/vendored/retrieval-agent-template || true
	gh repo clone langchain-ai/rag-research-agent-template democracy_exe/vendored/rag-research-agent-template || true
	gh repo clone langchain-ai/memory-template democracy_exe/vendored/memory-template || true
	gh repo clone langchain-ai/react-agent democracy_exe/vendored/react-agent || true
	gh repo clone langchain-ai/chat-langchain democracy_exe/vendored/chat-langchain || true
	gh repo clone bossjones/goob_ai democracy_exe/vendored/goob_ai || true

	rm -rf democracy_exe/vendored/cerebro-bot/.git
	rm -rf democracy_exe/vendored/sandbox_agent/.git
	rm -rf democracy_exe/vendored/retrieval-agent-template/.git
	rm -rf democracy_exe/vendored/rag-research-agent-template/.git
	rm -rf democracy_exe/vendored/memory-template/.git
	rm -rf democracy_exe/vendored/react-agent/.git
	rm -rf democracy_exe/vendored/chat-langchain/.git
	rm -rf democracy_exe/vendored/goob_ai/.git

marimo-edit:
	uv run marimo edit

# Automatically convert Jupyter notebooks. Automatically convert Jupyter notebooks to marimo notebooks with the CLI
marimo-convert:
	uv run marimo convert your_notebook.ipynb > your_notebook.py
