#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if (( $# > 1 )); then
  echo "usage: $0 [release-index.json]" >&2
  exit 64
fi
index="$repo_root/releases.json"
if (( $# == 1 )); then
  index="$1"
fi

jq -e '
  (keys | sort) == ["channel", "latest", "product", "releases", "schemaVersion"]
  and .schemaVersion == 1
  and .product == "Tinify for Mac"
  and .channel == "stable"
  and (.latest == null or (.latest | type == "string"))
  and (.releases | type == "array")
  and (
    .releases
    | all(
        . as $release
        | (keys | sort) == ["architectures", "build", "minimumMacOS", "publishedAt", "releaseNotesUrl", "releaseUrl", "version"]
        and (.version | test("^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"))
        and (.build | test("^[1-9][0-9]*$"))
        and (.publishedAt | fromdateiso8601 | type == "number")
        and (.releaseUrl == "https://github.com/Stianlars1/tinify-macos-releases/releases/tag/v\(.version)")
        and (.releaseNotesUrl == .releaseUrl)
        and (.minimumMacOS | test("^[0-9]+\\.[0-9]+$"))
        and (.architectures | type == "object")
        and (.architectures | keys | length >= 1)
        and (
          .architectures
          | to_entries
          | all(
              (.key == "arm64" or .key == "x86_64")
              and (.value | keys | sort) == ["bytes", "downloadUrl", "sha256"]
              and (
                .value.downloadUrl
                == "https://github.com/Stianlars1/tinify-macos-releases/releases/download/v\($release.version)/Tinify-\($release.version)-\(.key).dmg"
              )
              and (.value.sha256 | test("^[0-9a-f]{64}$"))
              and (
                .value.bytes
                | type == "number" and . > 0 and floor == .
              )
            )
        )
      )
  )
  and (
    if (.releases | length) == 0 then
      .latest == null
    else
      .latest == .releases[0].version
      and ([.releases[].version] | length == (unique | length))
      and (
        [.releases[].version | split(".") | map([length, .])] as $versions
        | all(
            range(1; $versions | length);
            $versions[. - 1] > $versions[.]
          )
      )
    end
  )
' "${index}" >/dev/null

while IFS= read -r version; do
  "$repo_root/scripts/validate-release-note.sh" \
    "$version" \
    "$repo_root/release-notes/v${version}.md"
done < <(jq -r '.releases[].version' "$index")

shopt -s nullglob
for release_note in "$repo_root"/release-notes/v*.md; do
  release_note_name="$(basename "$release_note")"
  release_note_version="${release_note_name#v}"
  release_note_version="${release_note_version%.md}"
  "$repo_root/scripts/validate-release-note.sh" \
    "$release_note_version" \
    "$release_note"
done

echo "Tinify for Mac release index verified"
