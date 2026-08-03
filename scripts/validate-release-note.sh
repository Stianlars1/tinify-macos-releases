#!/usr/bin/env bash
set -euo pipefail

if (( $# != 2 )); then
  echo "usage: $0 <version> <release-note.md>" >&2
  exit 64
fi

version="$1"
note="$2"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "invalid release-note version: $version" >&2
  exit 65
fi
if [[ ! -f "$note" || ! -r "$note" ]]; then
  echo "release note is missing or unreadable: $note" >&2
  exit 66
fi
if (( $(wc -c <"$note") > 24000 )); then
  echo "release note exceeds 24000 bytes: $note" >&2
  exit 67
fi

awk -v expected_title="# Tinify for Mac ${version}" '
  function fail(message) {
    print "invalid release note: " message " at line " NR > "/dev/stderr"
    exit 1
  }
  NR == 1 {
    if ($0 != expected_title) fail("unexpected title")
    next
  }
  /[<>]/ { fail("HTML-like content is not allowed") }
  /^$/ { next }
  /^## / {
    title = substr($0, 4)
    if (!(title == "Highlights" || title == "Improvements" ||
          title == "Fixes" || title == "Privacy and security" ||
          title == "Compatibility" || title == "Known issues")) {
      fail("unsupported section")
    }
    if (seen[title]++) fail("duplicate section")
    if (section_count > 0 && item_count == 0) fail("empty section")
    section_count++
    item_count = 0
    next
  }
  /^#/ { fail("unsupported heading") }
  {
    if (section_count == 0) {
      if ($0 ~ /^- /) fail("summary must be prose")
      summary_count++
    } else {
      if ($0 !~ /^- / || length($0) <= 2) fail("section content must be list items")
      item_count++
    }
  }
  END {
    if (summary_count == 0) fail("missing summary")
    if (section_count == 0) fail("missing sections")
    if (item_count == 0) fail("empty final section")
  }
' "$note"

echo "Tinify for Mac ${version} release notes verified"
