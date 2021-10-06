#!/usr/bin/env bash
###
### apps-matrix-output-from-git-diff.sh - Set Github Actions matrix variable
###
### Produces Github CI outputs of apps with changes suitable for passing into a jobs.strategy.matrix field.
### Uses `git diff` to discover which apps have changed from `master` based off listed repo paths.
### In CI, if the initial git diff - against HEAD^1 - fails, then will fall back to git diff HEAD~1
###
### Outputs:
###   matrix        { "app-name": [<JSON list of apps with changes since master>] }
###   changes       `true` if apps with changes detected, `false` otherwise.
###
### Usage:
###   apps-matrix-output-from-git-diff.sh [REFS...]
###
### Arguments
###   REFS          The git refs to diff. Can be any form accepted by `git diff`.
###                 Default: \$GITHUB_REF^1 or `git rev-parse --short=8 HEAD^1`

## Gets the absolute path for the root directory of the project
## When running in the github actions context, \$GITHUB_WORKSPACE will be set to the absolute path to the project root.
export PROJECT_DIR="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"

source "$PROJECT_DIR/.github/scripts/utils.sh"

function apps_with_changes_json_array() {
  local -r dir="$1"
  shift
  local -r refs=$*
  local -a apps

  echo "--> Looking for changes refs=$(join_by ":" $refs) root=$dir" >&2
  for app_dir in "$dir"/apps/*; do
    local app_name
    app_name=$(basename "$app_dir")

    ## paths to look for changes in
    ## paths are defined in .github/set-changed-apps-matrix.paths
    readarray -t paths < <(
      cat "$PROJECT_DIR/.github/git-diff.paths" | sed "/^#/d" | sed "/^[[:space:]]*$/d" | sed "s/__app__/$app_name/g"
    )

    ## Find any changes between the given \$refs with any files matching the given paths
    git_diff_output="$(git diff --name-only --exit-code $refs -- "${paths[@]}" 2>&1)"
    git_diff_status=$?

    if [[ "$CI" = "true" ]] && [[ $git_diff_status -gt 1 ]]; then
      echo "[WARN] git diff failed: $git_diff_output" >&2

      local -r head_ref="${GITHUB_SHA:-$(git rev-parse --short=8 HEAD)}~1"
      echo "--> Retrying git diff with ref=$head_ref" >&2
      git_diff_output="$(git diff --name-only --exit-code $head_ref -- "${paths[@]}" 2>&1)"
      git_diff_status=$?
    fi

    case "$git_diff_status" in
    0)
      echo "--> No changes detected for $app_name" >&2
      continue
      ;;
    1)
      {
        echo "--> Changes detected for $app"
        echo "$git_diff_output"
        echo
      } >&2
      apps+=($app_name)
      ;;
    *)
      echo "[ERR] Failed to run git diff: $git_diff_output" >&2
      continue
      ;;
    esac
  done

  echo "[\"$(join_by '","' ${apps[@]})\"]"
}

if [[ "$1" = '-h' ]] || [[ "$1" = '--help' ]]; then
  help
  exit 0
fi

refs="${@:-"${GITHUB_SHA:-$(git rev-parse --short=8 HEAD)}^1"}"
changed="$(apps_with_changes_json_array "$PROJECT_DIR" "$refs")"

echo "::set-output name=matrix::{\"app-name\":$changed}"
if [[ "$changed" = '[""]' ]]; then
  echo "::set-output name=changes::false"
else
  echo "::set-output name=changes::true"
fi
