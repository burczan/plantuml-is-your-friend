#!/usr/bin/env bash

set -o allexport
source ./.env
set +o allexport

if [ -d "$PROJECTS/$PROJECT_DIR" ]; then
  echo "$PROJECT_DIR directory already exist."
  exit 1
fi

mkdir "$PROJECTS/$PROJECT_DIR"

cp \
  --preserve \
  --recursive \
  "$ROOT"/templates/. "$ROOT/$PROJECTS/$PROJECT_DIR"/
