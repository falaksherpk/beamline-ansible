#!/usr/bin/env bash
# Lint the scripts beamline-ansible installs on the hosts (handbook Ch40): every tracked file
# whose first line is a Python or sh/bash shebang, and every template that renders a script.
#   ci/check-scripts.sh python   ruff check and ruff format --check (target: Python 3.12, the hosts')
#   ci/check-scripts.sh shell    ShellCheck; templates rendered first, with their role's defaults
# Each mode fails if it finds no file at all: a broken file list must not look like a pass.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Tracked files, not templates, whose first line matches the regex in $1.
by_shebang() {
  local f first
  while IFS= read -r -d '' f; do
    [[ $f == *.j2 ]] && continue
    first=""
    IFS= read -r first < "$f" || true
    if [[ $first =~ $1 ]]; then printf '%s\n' "$f"; fi
  done < <(git ls-files -z)
}

case ${1:-} in
  python)
    mapfile -t files < <(by_shebang '^#!.*python')
    (( ${#files[@]} )) || { echo "no Python scripts found" >&2; exit 1; }
    printf 'Python: %s\n' "${files[@]}"
    ruff check --no-cache "${files[@]}"
    ruff format --check --no-cache "${files[@]}"
    ;;
  shell)
    mapfile -t files < <(by_shebang '^#!(/usr/bin/env )?/?(usr/)?(bin/)?(ba)?sh( |$)')
    out=$(mktemp -d)
    trap 'rm -rf -- "$out"' EXIT
    # A template with a shebang is a script once rendered. Render it with its role's defaults
    # only; become is off, since ansible.cfg turns it on for the hosts.
    while IFS= read -r -d '' t; do
      IFS= read -r first < "$t" || true
      [[ $first == '#!'* ]] || continue
      role=${t#roles/}; role=${role%%/*}
      dest="$out/$(basename "${t%.j2}")"
      ANSIBLE_BECOME=false ansible localhost -c local -o -m ansible.builtin.template \
        -a "src=$PWD/$t dest=$dest mode=0644" -e "@roles/$role/defaults/main.yml" > /dev/null
      printf '%s (rendered from %s)\n' "$dest" "$t"
      files+=("$dest")
    done < <(git ls-files -z -- 'roles/*/templates/*.j2')
    (( ${#files[@]} )) || { echo "no shell scripts found" >&2; exit 1; }
    printf 'shell: %s\n' "${files[@]}"
    shellcheck "${files[@]}"
    ;;
  *)
    echo "usage: $0 python|shell" >&2; exit 2 ;;
esac
