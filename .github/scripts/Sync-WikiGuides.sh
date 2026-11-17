#!/usr/bin/env bash
# Copies the wiki guide pages from source/WikiSource at a given commit into a clone of
# the repository wiki, and stages the result there. It never deletes a wiki page: the
# wiki also holds the per-resource pages the release workflow generates, and pages that
# exist only in the wiki.
#
# Usage: Sync-WikiGuides.sh <repository directory> <wiki directory> [<module version>]
#
# The files are read from the commit (git show), not from the working copy, because
# .gitattributes checks every text file out with CRLF line endings and the wiki pages
# use LF.
set -euo pipefail

repo_dir=$1
wiki_dir=$2
version=${3:-}
source_dir='source/WikiSource'

if ! git -C "$repo_dir" cat-file -e "HEAD:$source_dir" 2>/dev/null; then
    echo "::notice::$source_dir does not exist at this commit. Nothing to publish."
    exit 0
fi

count=0
while IFS= read -r -d '' file; do
    relative=${file#"$source_dir"/}
    mkdir -p "$wiki_dir/$(dirname "$relative")"
    git -C "$repo_dir" show "HEAD:$file" > "$wiki_dir/$relative"
    count=$((count + 1))
done < <(git -C "$repo_dir" ls-tree -r -z --name-only HEAD -- "$source_dir/")

# The release build (Copy_Source_Wiki_Folder in DscResource.DocGenerator) replaces the
# '#.#.#' placeholder in Home.md with the module version. Do the same here, so a guide
# update between releases does not put the placeholder back on the wiki's front page.
if [[ -f "$wiki_dir/Home.md" ]]; then
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9]+)?$ ]]; then
        sed -i "s/#\.#\.#/$version/g" "$wiki_dir/Home.md"
    else
        echo "::warning::No released version was found, so the '#.#.#' placeholder in Home.md was left as it is."
    fi
fi

git -C "$wiki_dir" add --all
echo "Copied $count file(s) from $source_dir."
git -C "$wiki_dir" status --short
