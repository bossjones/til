# til

[![Docs](https://img.shields.io/badge/Docs-mkdocs-purple.svg?style=flat)](https://github.com/pages/bossjones/til)
[![github.com](https://img.shields.io/badge/git.corp-til-purple.svg?style=flat)](https://github.com/bossjones/til)
[![Code style: ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)

## What

A repository of random notes and snippets that I've found useful.

### Using Mkdocs

Here are some basic MkDocs commands in markdown format, suitable for a "Using MkDocs Quickstart" section:

## Using MkDocs: Quickstart

Here are some essential MkDocs commands to get you started:

### Create a New Project

To create a new MkDocs project, use the `new` command:

```bash
uv mkdocs new my-project
```

This will create a new directory named `my-project` containing a basic MkDocs configuration file and an initial documentation page[1a].

### Serve the Documentation

To preview your documentation as you work on it, use the `serve` command:

```bash
uv mkdocs serve
```

This will start a local development server, typically at `http://127.0.0.1:8000/`. The server will automatically reload when you make changes to your documentation[1a].

### Build the Site

To build your documentation site, use the `build` command:

```bash
uv mkdocs build
```

This command generates a static site in the `site` directory, which you can then deploy to a web server[1].

### Get Help

To see a list of all available commands and options, use the `--help` flag:

```bash
uv mkdocs --help
```

For help on a specific command, add `--help` after the command name:

```bash
uv mkdocs build --help
```

### Additional Commands

- **Clean Build**: To remove old files before building the site, use:
  ```bash
  uv mkdocs build --clean
  ```

- **Change Theme**: To specify a different theme when building, use:
  ```bash
  uv mkdocs build --theme readthedocs
  ```

- **Custom Configuration**: To use a custom configuration file, use:
  ```bash
  uv mkdocs build --config-file custom_mkdocs.yml
  ```

Remember to run these commands from the directory containing your `mkdocs.yml` configuration file[2][3].

Citations:
[1a] https://www.mkdocs.org/getting-started/
[2a] https://www.mkdocs.org/user-guide/cli/
[3a] https://mkdocs.readthedocs.io/en/restructure-compat/
[4a] https://github.com/mkdocs/mkdocs/blob/master/mkdocs/commands/new.py


### Prerequisites

- Python >= 3.12

### Get started

```shell
git clone git@github.com:bossjones/til.git
cd til
uv install
```

### Run tests

```shell
uv test
```

### Run lint and style checks

```shell
uv all-checks
```

E.g.:

```shell
bossjones at Marcs-MBP-3 in ~/dev/bossjones/til (bossjones/til)
$ uv all-checks
-------- lint-check ----------
All checks passed!
🎉 lint-check found no problems!
-------- style-check ----------
11 files already formatted
🎉 style-check found no problems!
-------- readme-lint ----------
🎉 readme-lint found no problems!
```
