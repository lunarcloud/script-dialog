#!/usr/bin/env bash
# Multi-UI Scripting
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license

# Get the directory where this script is located
SCRIPT_DIALOG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source all modular components
# shellcheck source=./init.sh
source "${SCRIPT_DIALOG_DIR}/init.sh"

# shellcheck source=./helpers.sh
source "${SCRIPT_DIALOG_DIR}/helpers.sh"

# shellcheck source=./messages.sh
source "${SCRIPT_DIALOG_DIR}/messages.sh"

# shellcheck source=./inputs.sh
source "${SCRIPT_DIALOG_DIR}/inputs.sh"

# shellcheck source=./lists.sh
source "${SCRIPT_DIALOG_DIR}/lists.sh"

# shellcheck source=./progressbar.sh
source "${SCRIPT_DIALOG_DIR}/progressbar.sh"

# shellcheck source=./pickers.sh
source "${SCRIPT_DIALOG_DIR}/pickers.sh"

# shellcheck source=./datepicker.sh
source "${SCRIPT_DIALOG_DIR}/datepicker.sh"
