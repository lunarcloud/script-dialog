#!/bin/bash
source $(dirname $(readlink -f $0))/script-ui.sh
relaunchIfNotVisible
superuser cp script-ui.sh /usr/local/bin/script-ui
superuser chmod +x /usr/local/bin/script-ui
