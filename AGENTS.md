# AI Instructions for script-dialog

This file provides specific context and instructions for AI coding agents to
interact effectively with this bash library.


## Project Overview

script-dialog is a GUI and TUI dialog abstraction library for OSes which bash runs on. It abstracts each "dialog" feature of the various tools, such as message boxes, progressbars, or file selectors.


## Technologies and Dependencies

* **Languages**: bash
* **Development Utilities**: [shellcheck]
* **Abstracted Utilities**: [zenity, kdialog, whiptail, dialog, echo, sudo]

## Project Structure

The repository is organized as follows:

* `script-dialog.sh`: Contains all code for the library.
* `test.sh`: the script which demonstrates all features of the library.

## Code Style and Conventions

* Follow shellcheck recommendations.
* Document all functions

### Running Quality Checks Locally

Before committing code, developers should run:

```bash
# Restore dependencies (ubuntu/debian syntax)
sudo apt install shellcheck

# Run the check
shellcheck script-dialog.sh
shellcheck test.sh

# Run unit tests
bash test.sh
```

And correct any remaining issues reported.

## Boundaries and Guardrails

* **NEVER** add a feature only supported on one OS.
* **NEVER** change the shell type.
* **NEVER** take non-obvious code from other projects.
