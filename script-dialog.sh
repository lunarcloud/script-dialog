#!/usr/bin/env bash
# Multi-UI Scripting
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Get the directory where this script is located
SCRIPT_DIALOG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source all modular components
# shellcheck source=./src/init.sh
source "${SCRIPT_DIALOG_DIR}/src/init.sh"

# shellcheck source=./src/helpers.sh
source "${SCRIPT_DIALOG_DIR}/src/helpers.sh"

# shellcheck source=./src/messages.sh
source "${SCRIPT_DIALOG_DIR}/src/messages.sh"

# shellcheck source=./src/inputs.sh
source "${SCRIPT_DIALOG_DIR}/src/inputs.sh"

# shellcheck source=./src/lists.sh
source "${SCRIPT_DIALOG_DIR}/src/lists.sh"

# shellcheck source=./src/progressbar.sh
source "${SCRIPT_DIALOG_DIR}/src/progressbar.sh"

# shellcheck source=./src/pickers.sh
source "${SCRIPT_DIALOG_DIR}/src/pickers.sh"

# shellcheck source=./src/datepicker.sh
source "${SCRIPT_DIALOG_DIR}/src/datepicker.sh"
