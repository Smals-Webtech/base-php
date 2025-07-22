#!/usr/bin/env bash

# Release script to create tags and manage Caddy module releases.
# This script follows semantic versioning and interacts with GitHub.
# It requires git, gh, and brew to be installed.

set -o nounset  # Exit on unset variable
set -o errexit  # Exit on error
set -o errtrace # Trace errors through functions
set -o pipefail # Catch errors in pipelines
#set -o xtrace         # Enable command tracing (for debugging)

# Function to check if required commands are installed
check_command() {
	if ! command -v "$1" >/dev/null; then
		echo "Error: The \"$1\" command must be installed." >&2
		exit 1
	fi
}

# Check for required commands
for cmd in git gh brew; do
	check_command "$cmd"
done

# Check if version argument is provided
if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <version>" >&2
	exit 1
fi

# Validate the provided version using semver regex
version_regex='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$'

if [[ ! $1 =~ $version_regex ]]; then
	echo "Invalid version number: $1. Please follow semantic versioning (e.g., 1.2.3)." >&2
	exit 1
fi

# Define version from argument
VERSION="$1"

# Ensure we are on the 'main' branch
echo "Switching to 'main' branch..."
git checkout main
git pull

# Commit changes (if any) and prepare for release
echo "Committing changes for version $VERSION..."
git commit -S -a -m "chore: prepare release $VERSION" || echo "No changes to commit."

# Create and sign the tag
echo "Creating tag $VERSION..."
git tag -s -m "Version $VERSION" "$VERSION"

# Push tags to remote
echo "Pushing tag $VERSION to remote..."
git push --follow-tags

# Get the previous tag based on semantic versioning
tags=$(git tag --list --sort=-version:refname '[0-9]*\.[0-9]*\.[0-9]*')
previous_tag=$(awk 'NR==2 {print; exit}' <<<"${tags}")

if [[ -z "$previous_tag" ]]; then
	echo "Error: Unable to find a previous tag." >&2
	exit 1
fi

# Create a new GitHub release with the generated notes
echo "Creating GitHub release for $VERSION..."
gh release create --generate-notes --latest --notes-start-tag "${previous_tag}" --verify-tag "$VERSION"

echo "Release $VERSION created successfully."
