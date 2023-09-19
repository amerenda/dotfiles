#!/bin/bash

log_directory="$HOME/.logs"

# Use 'find' to locate files older than 30 days and delete them
find "$log_directory" -type f -name "*.log" -mtime +5 -exec rm {} \;
find "$log_directory" -type f -name "*.error" -mtime +5 -exec rm {} \;
