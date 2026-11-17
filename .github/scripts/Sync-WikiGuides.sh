#!/usr/bin/env bash
# Makes the guide pages in a clone of the repository wiki match source/WikiSource at a
# given commit, and stages the result there.
#
# The repository is the authoritative source for the guides. A guide is added or
# overwritten from the repository, and a guide that was published by this script before
# and is no longer in source/WikiSource is deleted from the wiki. The script knows what
# it published from a manifest it keeps in the wiki (.guides-from-repository), so it
# never deletes anything else: the per-resource pages and the sidebar that the release
# workflow generates are not in the manifest and are left alone.
#
# Usage: Sync-WikiGuides.sh <repository directory> <wiki directory> [<module version>]
#
# Without a module version it asks GitHub for the latest full release, which needs
# GH_TOKEN and REPOSITORY (owner/name) in the environment.
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

manifest='.guides-from-repository'
published=()
while IFS= read -r -d '' file; do
    relative=${file#"$source_dir"/}
    mkdir -p "$wiki_dir/$(dirname "$relative")"
    git -C "$repo_dir" show "HEAD:$file" > "$wiki_dir/$relative"
    published+=("$relative")
done < <(git -C "$repo_dir" ls-tree -r -z --name-only HEAD -- "$source_dir/")
count=${#published[@]}

# An empty folder is far more likely to be a mistake than a decision to delete every
# guide, so it publishes nothing and deletes nothing.
if (( count == 0 )); then
    echo "::warning::$source_dir holds no files. Nothing was published or deleted."
    exit 0
fi

# Delete the guides this script published before that are gone from the repository.
# The manifest lives in the wiki, which can be edited by hand, so an entry is only
# honoured if it is a plain relative path to a file git tracks inside the wiki.
removed=0
if [[ -f "$wiki_dir/$manifest" ]]; then
    while IFS= read -r previous || [[ -n "$previous" ]]; do
        previous=${previous%$'\r'}
        [[ -z "$previous" || "$previous" == /* || "$previous" == *..* || "$previous" == .git/* ]] && continue
        [[ "$previous" == "$manifest" ]] && continue
        still_published=false
        for current in "${published[@]}"; do
            if [[ "$current" == "$previous" ]]; then
                still_published=true
                break
            fi
        done
        "$still_published" && continue
        if git -C "$wiki_dir" ls-files --error-unmatch -- "$previous" > /dev/null 2>&1; then
            git -C "$wiki_dir" rm --quiet -- "$previous"
            echo "Deleted $previous, which is no longer in $source_dir."
            removed=$((removed + 1))
        fi
    done < "$wiki_dir/$manifest"
fi

printf '%s\n' "${published[@]}" | LC_ALL=C sort > "$wiki_dir/$manifest"

# The version shown on the wiki's Home page is the latest full release, which is what a
# reader installs by default.
if [[ -z "$version" && -n "${REPOSITORY:-}" ]]; then
    tag=$(gh api "repos/$REPOSITORY/releases/latest" --jq '.tag_name' 2>/dev/null || true)
    version=${tag#v}
fi

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
echo "Copied $count file(s) from $source_dir and deleted $removed."

summary=${GITHUB_STEP_SUMMARY:-/dev/null}
if git -C "$wiki_dir" diff --cached --quiet; then
    echo 'The wiki guides already match the repository.' | tee -a "$summary"
else
    {
        echo '### Wiki guide changes'
        echo '```'
        git -C "$wiki_dir" diff --cached --stat
        echo '```'
    } | tee -a "$summary"
fi
