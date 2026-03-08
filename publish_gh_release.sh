#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2181,SC2034,SC2116

## Author: Tommy Miland (@tmiland) - Copyright (c) 2026


######################################################################
####                 Publish Github Release.sh                    ####
####            A script to publish github releases               ####
####                   Maintained by @tmiland                     ####
######################################################################


VERSION='1.0.1'

#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2026
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
## for debugging purpose
if [[ $* == "debug" ]]; then
  set -o errexit
  set -o pipefail
  set -o nounset
  set -o xtrace
fi
# Get Current directory
REPO_DIR=$(pwd)
# Get repo name
# REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
# https://www.w3tutorials.net/blog/how-do-you-get-the-git-repository-s-name-in-some-git-repository/
REPO_NAME=$(git remote show origin | grep "Fetch URL" | sed -n 's/.*\/\([^\/]*\)\.git$/\1/p')
# Get release filename
# RELEASE_FILE_NAME=$(echo "${REPO_NAME//-/_}")
# RELEASE_FILE_NAME=$(echo "${RELEASE_FILE_NAME,,}")
# RELEASE_FILE="$RELEASE_FILE_NAME.sh"
RELEASE_FILE=$(grep -l "VERSION='1.0.1'
YEAR=$(date +%Y)

GH_REPO_USER=tmiland
GH_REPO=$REPO_NAME
GH_USER=$GH_REPO_USER
GH_TOKEN=$(cat "${HOME}"/.credentials/.ghtoken)
GH_TARGET=$(git status | grep -oP "On branch \K.*")

# ANSI Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'    # Reset color

# Print an error message and exit (Red)
error() {
  printf "${RED}ERROR: %s${RESET}\n" "$*" >&2
  exit 1
}

# Print a log message (Green)
ok() {
  printf "${GREEN}%s${RESET}\n" "$*"
}

warn() {
  printf "${YELLOW}%s${RESET}\n" "$*"
}

cd "${REPO_DIR}" || exit
# Always set Copyright year to current year
sed -i "s|Copyright (c) 2026

RELEASE_VERSION='1.0.1'
  grep '"tag_name":' |
  sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p')
  # sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p' "$REPO_DIR/$RELEASE_FILE"
LOCAL_VERSION='1.0.1'

RELEASE_NOTES=$(curl -sL \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/${GH_REPO_USER}/${GH_REPO}/releases/generate-notes \
  -d '{"tag_name":"v'$RELEASE_VERSION'","target_commitish":"'$GH_TARGET'","previous_tag_name":"v'$LOCAL_VERSION'"}' \
  | jq -r '.body')

publish_release() {
  git add -A >/dev/null 2>&1 || error "Unable to run git add -A"
  git commit -m "Update $REPO_NAME version to $LOCAL_VERSION" || error "Unable to run git commit -m Update $REPO_NAME version to $LOCAL_VERSION"
  git push -u origin "$GH_TARGET" >/dev/null 2>&1 || error "git push -u origin $GH_TARGET"

  RELEASE=$(curl --silent --user "$GH_USER:$GH_TOKEN" -X POST https://api.github.com/repos/${GH_REPO_USER}/${GH_REPO}/releases \
      -d "
    {
      \"tag_name\": \"v$LOCAL_VERSION\",
      \"target_commitish\": \"$GH_TARGET\",
      \"name\": \"v$LOCAL_VERSION\",
      \"body\": \"$1\n\n$RELEASE_NOTES\",
      \"draft\": false,
      \"prerelease\": false
  }")

  RELEASE_ID=$(echo ${RELEASE} | jq -r .id)
  curl --silent --user "$GH_USER:$GH_TOKEN" -X POST https://uploads.github.com/repos/${GH_REPO_USER}/${GH_REPO}/releases/${RELEASE_ID}/assets?name=${RELEASE_FILE} \
    --header 'Content-Type: text/javascript ' --upload-file ${RELEASE_FILE} >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
      ok "Success!"
    else
      error "ERROR! Something went wrong."
    fi
}

if [[ "$LOCAL_VERSION" == "$RELEASE_VERSION" ]]
then
  read -rp "Looks like published release is the same version as local, do you want to increment it? [y/n] " YESNO
  if [ "$YESNO" == "y" ]
  then
    # https://stackoverflow.com/a/70595817
    # LOCAL_VERSION='1.0.1'

    # Source: https://gist.github.com/siddharthkrish/32072e6f97d7743b1a7c47d76d2cb06c
    # Corrected according to https://semver.org
    version="$LOCAL_VERSION"
    major=0
    minor=0
    patch=0
    # break down the version number into it's components
    regex="([0-9]+).([0-9]+).([0-9]+)"
    if [[ $version =~ $regex ]]; then
      major="${BASH_REMATCH[1]}"
      minor="${BASH_REMATCH[2]}"
      patch="${BASH_REMATCH[3]}"
    fi
    REPLY=${REPLY:-patch}
    read -rep "  Enter [major/minor/patch]: " -i "$REPLY" REPLY
    # check paramater to see which number to increment
    if [[ "$REPLY" == "major" ]]; then
      major=$(echo "$major"+1 | bc)
      minor=0
      patch=0
    elif [[ "$REPLY" == "minor" ]]; then
      minor=$(echo "$minor"+1 | bc)
      patch=0
    elif [[ "$REPLY" == "patch" ]]; then
      patch=$(echo "$patch"+1 | bc)
    else
      warn "usage: Enter [major/minor/patch]"
      exit 1
    fi
    LOCAL_VERSION='1.0.1'
    # echo the new version number
    echo "New version: v${LOCAL_VERSION}"
    sed -i "s|VERSION='1.0.1'
    echo "Local version incremented to v$LOCAL_VERSION"
    echo "Publishing $REPO_NAME release version v$LOCAL_VERSION"
    publish_release "Update $REPO_NAME version from v$RELEASE_VERSION to v$LOCAL_VERSION"
    exit 0
  fi
fi

if [ -z "$RELEASE_VERSION" ]
then
  read -rp "Looks like this is your first release, do you want to publish it? [y/n]" YESNO
  if [ "$YESNO" == "y" ]; then
    ok "Publishing $REPO_NAME release version v$LOCAL_VERSION"
    RELEASE_NOTES="" \
    publish_release "First release of $REPO_NAME release version v$LOCAL_VERSION"
    exit 0
  fi
else
  if [[ "$RELEASE_VERSION" < ${LOCAL_VERSION} ]]
  then
    warn "Current $REPO_NAME Version: v$RELEASE_VERSION => New Version: v$LOCAL_VERSION"
    ok "Publishing $REPO_NAME release version v$LOCAL_VERSION"
    publish_release
    exit 0
  else
    warn "Latest $REPO_NAME version already released"
  fi
fi

exit 0