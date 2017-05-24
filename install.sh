#!/bin/bash
source $(dirname $(readlink -f $0))/script-dialog.sh
relaunchIfNotVisible
superuser cp script-dialog.sh /usr/local/bin/script-dialog
superuser chmod +x /usr/local/bin/script-dialog
