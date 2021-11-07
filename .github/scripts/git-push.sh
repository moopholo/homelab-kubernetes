#!/usr/bin/env bash
git config user.name "github-actions"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git pull --rebase --autostash

max_attempts=5
attempt=0

until git push; do
  command_status=$?
  if ((attempt == max_attempts)); then
    exit $command_status
  else
    ((attempt += 1))
    pause=$(echo "scale=4; $attempt * (0.8 + $RANDOM/10000)" | bc)
    echo "[ERROR] command failed. Retry in $pause seconds..."
    git pull --rebase --autostash
    sleep "$pause"
  fi
done
