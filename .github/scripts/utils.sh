#!/usr/bin/env bash

function help() {
  sed -rn 's/^### ?//;T;p' "$0"
}

function join_by() {
  local d=$1
  shift
  local f=$1
  shift
  printf %s "$f" "${@/#/$d}"
}
