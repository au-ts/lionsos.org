#!/usr/bin/env bash

set -euo pipefail

rsync --archive --verbose --compress --partial --delete \
    --filter='protect /downloads/' \
    lionsos_docs/ lions-www.keg.cse.unsw.edu.au:/var/www/html
