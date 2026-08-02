# Tinify for Mac releases

This is the public release and issue repository for Tinify for Mac. It contains
release metadata, checksums, release notes and downloadable release assets. The
application source code is maintained separately and is not published here.

No release is considered public until it appears in both:

- [`releases.json`](./releases.json); and
- [GitHub Releases](https://github.com/Stianlars1/tinify-macos-releases/releases).

Official downloads will also be published at `https://tinify.dev/downloads`.
Sparkle updates use the separately signed architecture feed at
`https://updates.tinify.dev/stable/<architecture>/appcast.xml`.

## Verify a download

Every published architecture entry records the exact byte length and SHA-256
of its notarized and stapled DMG. Stable assets use the exact name
`Tinify-<version>-<architecture>.dmg` under the matching `v<version>` tag. On
macOS:

```sh
shasum -a 256 /path/to/Tinify.dmg
xcrun stapler validate /path/to/Tinify.dmg
spctl --assess --type open \
  --context context:primary-signature \
  --verbose=4 \
  /path/to/Tinify.dmg
```

## Support

- Product questions: `support@larsenutvikling.no`
- Bugs and feature requests: [open an issue](https://github.com/Stianlars1/tinify-macos-releases/issues)
- Security reports: follow [`SECURITY.md`](./SECURITY.md); do not file a public
  issue for a vulnerability.
