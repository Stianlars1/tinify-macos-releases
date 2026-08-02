#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
index="${repo_root}/releases.json"

jq -e '
  .schemaVersion == 1
  and .product == "Tinify for Mac"
  and .channel == "stable"
  and (.latest == null or (.latest | type == "string"))
  and (.releases | type == "array")
  and (
    .releases
    | all(
        (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
        and (.build | test("^[1-9][0-9]*$"))
        and (.publishedAt | fromdateiso8601 | type == "number")
        and (.releaseUrl | test("^https://github\\.com/Stianlars1/tinify-macos-releases/releases/tag/"))
        and (.releaseNotesUrl | test("^https://github\\.com/Stianlars1/tinify-macos-releases/releases/tag/"))
        and (.minimumMacOS | test("^[0-9]+\\.[0-9]+$"))
        and (.architectures | type == "object")
        and (.architectures | keys | length >= 1)
        and (
          .architectures
          | to_entries
          | all(
              (.key == "arm64" or .key == "x86_64")
              and (.value.downloadUrl | test("^https://github\\.com/Stianlars1/tinify-macos-releases/releases/download/"))
              and (.value.sha256 | test("^[0-9a-f]{64}$"))
              and (.value.bytes | type == "number" and . > 0)
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
    end
  )
' "${index}" >/dev/null

echo "Tinify for Mac release index verified"
