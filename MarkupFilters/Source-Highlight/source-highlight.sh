#!/bin/zsh

program_name="$(basename "$0")"

language_string_with_sh="${program_name/#source-highlight_/}"
language_string="${language_string_with_sh/%.sh/}"

exec /opt/local/bin/source-highlight -s "$language_string"

