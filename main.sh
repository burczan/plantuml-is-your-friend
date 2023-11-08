#!/usr/bin/env bash

set -o allexport
source ./.env
set +o allexport

if [ ! -d "$PROJECTS/$PROJECT_DIR" ]; then
  echo "$PROJECTS/$PROJECT_DIR directory does not exist."
  exit 1
else
  echo "PROJECT_DIR: $PROJECT_DIR"
fi

# =========
# FUNCTIONS
# =========

function log {
  message=$1
  echo -e "$message"
}

function log_ok {
  message=$1
  echo -e "${GREEN}$message${ENDCOLOR}"
}

function log_info {
  message=$1
  echo -e "${BLUE}$message${ENDCOLOR}"
}

function log_warn {
  message=$1
  echo -e "${ORANGE}$message${ENDCOLOR}"
}

function log_err {
  message=$1
  echo -e "${RED}$message${ENDCOLOR}"
}

function log_self {
  function_name=$1
  log_info "Running $function_name..."
}

function help {
  log_info "Usage: $(basename "$0") [options]"
  echo "--help                   Display this help"
  echo "--name=NAME              Specify directory to run script for"
  echo "--check_syntax           Check syntax of PlantUML files (.iuml and .puml)"
  echo "--compute_encoded_url    Compute the encoded URL of $MAIN_PUML_FILE"
  echo "--generate_svg           Generate SVG image from $MAIN_PUML_FILE"
  echo "--generate_server_url    Generate PlantUML server url"
  echo "--generate_preproc_file  Generate preprocessor text of $MAIN_PUML_FILE"
  echo "--run_plantuml_server    Run PlantUML Server (Docker based)"
  exit 0
}

function restore_root_path {
  cd "$ROOT" || exit
}

function go_to_project_dir {
  cd "$PROJECTS/$PROJECT_DIR" || exit
}

function print_server_container_status {
  docker ps \
    --filter "name=$SERVER_CONTAINER_NAME" \
    --format "table {{.ID}}\t{{.Names}}\t{{.State}}\t{{.Ports}}"
}

function run_plantuml_server {
  log_self "${FUNCNAME[0]}"

  output=$(print_server_container_status 2>&1)

  if echo "$output" | grep "$SERVER_CONTAINER_NAME" >/dev/null; then
    log_warn "PlantUML server is already running."
    log "$output"
  else
    docker run \
      --detach \
      --name "$SERVER_CONTAINER_NAME" \
      -p 8080:8080 \
      plantuml/plantuml-server:jetty

    log_ok "PlantUML server started."
  fi
}

# https://plantuml.com/command-line
# https://plantuml.com/security
function __plantuml_cli {
  docker run \
    --rm -i \
    --volume "$PWD":/wd \
    --workdir /wd \
    --env _JAVA_OPTIONS="\
    -Dplantuml.include.path=/include \
    -DPLANTUML_SECURITY_PROFILE=UNSECURE" \
    --volume """$PWD""":/include \
    ghcr.io/plantuml/plantuml "$@"
}

function get_plantuml_files {
  restore_root_path
  find "$PROJECTS/$PROJECT_DIR" -name "*.puml" -or -name "*.iuml"
}

# https://plantuml.com/faq#fb512f3bcb2c5b7d
# file with bom still doesn't work
function verify_bom() {
  log_self "${FUNCNAME[0]}"

  function __verify_bom_file {
    file="$1"
    if
      head -c3 "$file" | LC_ALL=C grep -qP '\xef\xbb\xbf'
    then
      log_err "$file file has utf8bom encoding, change to utf8."
      exit 1
    fi
  }

  local plantuml_files
  plantuml_files=$(get_plantuml_files)

  for file in $plantuml_files; do
    __verify_bom_file "$file"
  done
}

function check_syntax {
  log_self "${FUNCNAME[0]}"

  local plantuml_files
  plantuml_files=$(get_plantuml_files)

  restore_root_path
  go_to_project_dir

  for filepath in $plantuml_files; do
    filename=$(basename -- "$filepath")
    log_info "$filepath:"
    __plantuml_cli -checkonly -stdrpt:1 "$filename" && log
  done
}

function generate_svg {
  log_self "${FUNCNAME[0]}"
  restore_root_path
  go_to_project_dir

  __plantuml_cli -tsvg \
    -stdrpt:1 \
    -noerror \
    "$MAIN_PUML_FILE"
}

# https://plantuml.com/preprocessing
function generate_preproc_file {
  log_self "${FUNCNAME[0]}"
  restore_root_path
  go_to_project_dir

  __plantuml_cli -preproc \
    -stdrpt:1 \
    -failfast2 \
    "$MAIN_PUML_FILE"
}

function compute_encoded_url {
  log_self "${FUNCNAME[0]}"
  restore_root_path
  go_to_project_dir

  __plantuml_cli -computeurl \
    -stdrpt:1 \
    "$MAIN_PUML_FILE" >"$URL_FILE_PATH"

  log_info "Saved in $PROJECT_DIR/$URL_FILE_PATH"
}

function generate_server_url {
  log_self "${FUNCNAME[0]}"
  run_plantuml_server

  log_info "\nDiagram url:"
  hash=$(cat "./$PROJECTS/$PROJECT_DIR/$URL_FILE_PATH")
  log "http://localhost:8080/uml/$hash"
}

# ====================================
# MAIN
# modified version of
# https://stackoverflow.com/a/29754866
# ====================================

# getopt - Man Page
# --test
#   Test if your getopt(1) is this enhanced version or an old version.
#   This generates no output, and sets the error status to 4.
#   Other implementations of getopt(1), and this version if the environment
#   variable GETOPT_COMPATIBLE is set, will return '--' and error status 0.
getopt --test >/dev/null

if [[ $? -ne 4 ]]; then
  echo "$(getopt --test) failed in this environment."
  exit 1
fi

declare -A OPTIONS=(
  ["h"]="help"
  ["n:"]="name:"
  ["s"]="check_syntax"
  ["e"]="compute_encoded_url"
  ["r"]="run_plantuml_server"
  ["p"]="generate_preproc_file"
  ["g"]="generate_svg"
  ["u"]="generate_server_url"
)

long_opts=()
short_opts=()

for key in "${!OPTIONS[@]}"; do
  short_opts+=("$key")
  long_opts+=("${OPTIONS[$key]}")
done

function join_by {
  local IFS="$1"
  shift
  echo "$*"
}

PARSED_OPTIONS=$(
  getopt \
    --options="$(join_by "" "${short_opts[@]}")" \
    --longoptions="$(join_by , "${long_opts[@]}")" \
    --name "$0" -- "$@"
)

eval set -- "$PARSED_OPTIONS"

while true; do
  case "$1" in
  -n | --name)
    PROJECT_DIR=$2
    shift 2
    ;;
  -h | --help)
    shift
    help
    ;;
  -s | --check_syntax)
    shift
    verify_bom
    check_syntax
    ;;
  -e | --compute_encoded_url)
    shift
    compute_encoded_url
    ;;
  -r | --run_plantuml_server)
    shift
    run_plantuml_server
    ;;
  -p | --generate_preproc_file)
    shift
    generate_preproc_file
    ;;
  -g | --generate_svg)
    generate_svg
    shift
    ;;
  -u | --generate_server_url)
    generate_server_url
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Error"
    exit 3
    ;;
  esac
done
