# Bash Opts [![Build Status](https://travis-ci.org/svenfuchs/bash_opts.svg?branch=master)](https://travis-ci.org/svenfuchs/bash_opts)

Simple Bash options parser, no shit.

Bash Opts expects you to define a list of options, and then call `opts_eval`
with an array of arguments to parse (usually `"$@"`). It will then match the
given arguments against the defined options, and define variables ready for
you to be used.

E.g. the following lines will output `Bash Opts`:

```bash
opts --name=
opts_eval "--name=Bash Opts"
echo $name
```

Any remaining arguments that do not match your options cannot start with a dash
(protecting against typos and wrong option definitions), and will be collected
in an array variable `args`, also for you to be used.

E.g. this will output `foo bar`:

```bash
opts --name=
opts_eval "foo" "bar" "--name=Bash Opts"
echo ${args[@]}
```

More detailed usage example (see ./examples/readme.sh):

```bash
#!/bin/bash

opts --[d]ebug --[n]ame= --[f]iles[]=
opts_eval "$@"

echo "debug: $debug"
echo "name: $name"
echo "files: ${files[@]}"
echo "args: ${args[@]}"
```

Call with:

```bash
$ bash examples/readme.sh arg-1 arg-2 -d --name="Bash Opts" -f=path/to/foo.sh -f=path/to/bar.sh
# or: bash examples/readme.sh arg-1 -d -n "Bash Opts" -f path/to/foo.sh -f path/to/bar.sh arg-2
# or: bash examples/readme.sh --debug arg-1 --name="Bash Opts" arg-2 --file=path/to/foo.sh --file=path/to/bar.sh
# or: bash examples/readme.sh --debug --name "Bash Opts" arg-1 --file path/to/foo.sh arg-2 --file path/to/bar.sh

debug: true
name: Bash Opts
files: path/to/foo.sh path/to/bar.sh
args: arg-1 arg-2```
```

Options need to be defined as long names, as in `--debug`. Short names can be
defined by enclosing contained characters in square brackes, e.g. `--[d]ebug`.
It is not possible to define a short name without also defining a long name, or
to define a short name with characters that are not contained in the long name.

There are three types of options:

### Flags

Flags, e.g. `--debug`, do not take a value.

A flag is defined as just `--debug`. When evaluated it always sets its
corresponding variable to either `true` or `false` (as strings). I.e. the
condition `[[ $debug == true ]]` will match when `--debug` was evaluated.

### Variables

Plain variables, e.g. `--name=`, expect a value.

A variable is defined by terminating the name with an equal sign `=`. Variables
match a single passed argument with an equal sign separating name and value
(e.g. `--name="Bash Options"`), or two passed arguments when the name does not
end with an equal sign (e.g. `--name "Bash Options"`).

### Arrays

Arrays, e.g. `--files[]=`, expect a value, too, and can be passed several times.

An Array option will result in an array variable with the same plural name.
They match one or many arguments with their singular name.

E.g. `--file 1.sh --file 2.sh` will evalute to an array variable `files` which
contains two strings `1.sh` and `2.sh`.

### Remaining argumetns

Arguments that do not match any of the defined options, and that do not begin
with a dash `-`, will end up in an array variable `args`.

Such arguments can be given at any position between valid options. However,
obviously, they must not sit between a variable option and its corresponding
value argument when using the syntax without an equal sign (as in `--name
foo`).
