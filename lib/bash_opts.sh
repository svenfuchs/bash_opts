#!/bin/bash

declare -a __OPTS__ __ARGS__ __VARS__

function opts() {
  function opt_name() {
    local opt=$1
    local type=$(opt_type $opt)
    local name=$(echo ${opt/--no-/} | tr -d '\-=[]')
    [[ $type == array && ${name: -1} == s ]] && name=${name%?} || true
    echo $name
  }

  function var_name() {
    local opt=$1
    echo ${opt/--no-/} | tr -d '\-=[]'
  }

  function short_name() {
    local opt=$1
    local name=${opt/[]//}
    [[ $name =~ (\[(.)\]) ]] && echo ${BASH_REMATCH[2]} || true
  }

  function opt_type() {
    local opt=$1
    local type=flag
    [[ ! $opt =~ =$   ]] || type=var
    [[ ! $opt =~ '[]' ]] || type=array
    echo $type
  }

  function negated() {
    local opt=$1
    [[ $opt =~ ^--no- ]] && echo true || echo false
  }

  local opts=("$@")

  for opt in ${opts[@]}; do
    __OPTS__[${#__OPTS__[@]}]="
      opt=$(opt_name $opt)
      name=$(var_name $opt)
      type=$(opt_type $opt)
      short=$(short_name $opt)
      negated=$(negated $opt)
    "
  done
}
export -f opts

function opts_eval() {
  function puts() {
    echo "$@" >&2
  }

  function opts_declare() {
    for opt in "${__OPTS__[@]}"; do
      local type name short negated
      eval "$opt"
      [[ $type != array ]] || store_var "$name=()"
      [[ $type != flag ]]  || store_var "$name=$([[ $negated == true ]] && echo true || echo false)"
    done
  }

  function opt_value() {
    local arg=$1 opt=$2 name=$3 short=$4 value=

    if [[ $arg =~ --$opt=(.*)$ || $arg =~ -$short=(.*)$ ]]; then
      value=${BASH_REMATCH[1]}
    elif [[ $arg =~ --$opt || $arg == -$short ]]; then
      read value
    fi

    [[ -n $value ]] && echo $value
  }

  function store_var() {
    __VARS__[${#__VARS__[@]}]="$1"
  }

  function set_var() {
    local name=$3 value=
    value=$(opt_value "$@")
    [[ -n $value ]] && store_var "$name=\"$value\""
  }

  function set_array() {
    local name=$3 value=
    value=$(opt_value "$@")
    [[ -n $value ]] && store_var "$name[\${#$name[@]}]=\"$value\""
  }

  function set_flag() {
    local arg=$1 opt=$2 name=$3 short=$4 value=

    if [[ $arg == -$short ]]; then
      value=true
    elif [[ $arg =~ --(no-)?$opt$ ]]; then
      value=$([[ -n ${BASH_REMATCH[1]} ]] && echo false || echo true)
    fi

    [[ -n $value ]] && store_var "$name=$value"
  }

  function opts_parse() {
    local arg=$1

    for opt in "${__OPTS__[@]}"; do
      local type name short negated value
      eval $opt
      if set_$type "$arg" "$opt" "$name" "$short"; then
        return 0
      fi
    done

    return 1
  }

  local in=/tmp/bash_opts.in.$$$RANDOM
  touch $in
  trap "rm -f $in" exit
  exec 6<&0 <$in

  for arg in "$@"; do
    printf "%s\n" "$arg" >> $in;
  done
  # __ARGS__=("${args[@]}")
  args=(0)
  opts_declare

  while read arg; do
    if opts_parse "$arg"; then
      # eval $var
      true
    elif [[ $arg =~ ^- ]]; then
      echo "Unknown option: ${arg}" >&2 && exit 1
    else
      args[${#args[@]}]="$arg"
    fi
  done < $in

  for var in "${__VARS__[@]}"; do
    eval $var
  done

  exec 0<&6 6<&-

  args=(${args[@]:1})
}
export -f opts_eval

if [[ $0 == $BASH_SOURCE ]]; then
  args=("--foo=FOO" "--fuu" "FUU" "arg-1" "--bar=1" "--bar=2" "--baz" "--no-buz" "arg-2 --bum=3") # "--boz")
  # args=("--foo=FOO" "--fuu=FUU")
  # args=("--foo" "FOO")
  # args=("--foo", "FOO BAR")

  echo args: ${args[@]}
  echo opts: --[f]oo= --bars[]= --[b]az --no-buz
  opts --[f]oo= --fuu= --bars[]= --[b]az --no-buz
  opts_eval "${args[@]}"

  echo
  echo foo: ${foo:=}
  echo fuu: ${fuu:=}
  [[ ${#bars[@]} == 0 ]] || for bar in ${bars[@]}; do echo bar: $bar; done
  echo baz: ${baz:=}
  echo buz: ${buz:=}

  echo
  echo args: ${#args[@]}
  [[ ${#args[@]} == 0 ]] || for arg in "${args[@]}"; do echo arg: "$arg"; done
fi
