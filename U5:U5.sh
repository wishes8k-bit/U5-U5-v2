#!/bin/sh
printf '\033c\033]0;%s\a' U5-U5
base_path="$(dirname "$(realpath "$0")")"
"$base_path/U5:U5.arm64" "$@"
