#!/usr/bin/env bash
# Repository settings as code: compares the repository with the files below, or applies them.
#
#   .github/rulesets/*.json      branch rulesets, in GitHub's ruleset export format, matched by name
#   .github/repo-settings.json   repository settings (PATCH /repos/...), plus the private
#                                vulnerability reporting switch, which has an endpoint of its own
#
# Usage: gh-settings.sh diff|apply OWNER/REPO
#
# `diff` only reads. `apply` needs admin rights on the repository and is meant to be run by a
# maintainer, never by CI. A comparison only looks at the keys the files set: GitHub returns many
# defaults the files do not mention, and a rule the repository has but no file names is reported.
set -euo pipefail

action=${1:?usage: gh-settings.sh diff|apply OWNER/REPO}
repo=${2:?usage: gh-settings.sh diff|apply OWNER/REPO}
dir=$(cd "$(dirname "$0")" && pwd)

# The current value restricted to the shape of the wanted one. A list of objects carrying a `type`
# (ruleset rules) is matched by type; any other value is taken whole.
read -r -d '' PROJECT <<'JQ' || true
def proj($w; $c):
  if ($w | type) == "object" then
    reduce ($w | keys[]) as $k ({}; .[$k] = proj($w[$k]; ($c // {})[$k]))
  elif ($w | type) == "array" and ($w | length) > 0 and ($w[0] | type) == "object" and ($w[0] | has("type")) then
    [ $w[] as $wr | proj($wr; (($c // []) | map(select(.type == $wr.type)) | first)) ]
    + [ ($c // [])[] | select(.type as $t | ($w | map(.type) | index($t)) == null) | {type, not_in_file: true} ]
  else $c end;
proj($want; $cur)
JQ

compare() { # name, wanted json, current json
  local name=$1 want=$2 cur=$3 projected
  projected=$(jq -S --argjson want "${want}" --argjson cur "${cur}" -n "${PROJECT}")
  if diff -u --label "github: ${name}" --label "file: ${name}" \
      <(echo "${projected}") <(jq -S . <<<"${want}"); then
    echo "in sync: ${name}"
  else
    differs=1
  fi
}

ruleset_id() { # name -> id, empty when absent
  gh api "repos/${repo}/rulesets?includes_parents=false" --jq ".[] | select(.name == \"$1\") | .id"
}

current_settings() {
  local pvr
  pvr=$(gh api "repos/${repo}/private-vulnerability-reporting" --jq .enabled)
  gh api "repos/${repo}" | jq --argjson pvr "${pvr}" '. + {private_vulnerability_reporting: $pvr}'
}

differs=0
case "${action}" in
  diff)
    for f in "${dir}"/rulesets/*.json; do
      name=$(jq -r .name "${f}")
      id=$(ruleset_id "${name}")
      if [ -z "${id}" ]; then
        echo "missing on GitHub: ruleset ${name}"
        differs=1
        continue
      fi
      compare "ruleset ${name}" "$(cat "${f}")" "$(gh api "repos/${repo}/rulesets/${id}")"
    done
    compare "repository settings" "$(cat "${dir}/repo-settings.json")" "$(current_settings)"
    [ "${differs}" = 0 ] && echo "${repo} matches the files." || echo "${repo} differs from the files (see above)."
    ;;
  apply)
    for f in "${dir}"/rulesets/*.json; do
      name=$(jq -r .name "${f}")
      id=$(ruleset_id "${name}")
      if [ -z "${id}" ]; then
        gh api -X POST "repos/${repo}/rulesets" --input "${f}" --jq '"created ruleset \(.name) (\(.id))"'
      else
        gh api -X PUT "repos/${repo}/rulesets/${id}" --input "${f}" --jq '"updated ruleset \(.name) (\(.id))"'
      fi
    done
    jq 'del(.private_vulnerability_reporting)' "${dir}/repo-settings.json" |
      gh api -X PATCH "repos/${repo}" --input - --jq '"updated repository settings of \(.full_name)"'
    if [ "$(jq -r .private_vulnerability_reporting "${dir}/repo-settings.json")" = true ]; then
      gh api -X PUT "repos/${repo}/private-vulnerability-reporting" --silent
      echo "private vulnerability reporting enabled"
    else
      gh api -X DELETE "repos/${repo}/private-vulnerability-reporting" --silent
      echo "private vulnerability reporting disabled"
    fi
    ;;
  *)
    echo "unknown action ${action}: diff or apply" >&2
    exit 2
    ;;
esac
