#!/bin/bash

source lib/bash_opts.sh

opts --[d]ebug --[n]ame= --[f]iles[]=
opts_eval "$@"

echo "debug: $debug"
echo "name: $name"
echo "files: ${files[@]}"
echo "args: ${args[@]}"
