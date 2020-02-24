#!/usr/bin/env bash

restic -r b2:amer-backup:sleeperservice backup / --exclude-file=meta/backup/exclude.txt -o b2.connections=10
