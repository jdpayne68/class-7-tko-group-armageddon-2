# Badge Logo Assets

Local SVG source assets for logos referenced by the badge library.

These files are provided so badge logos can be inspected, restyled, regenerated, or embedded into custom Shields.io badge URLs without reverse-engineering existing Markdown links.

## Layout

```text
assets/logos/
├── custom/          # Custom inline SVG logos used directly in badge data URIs
├── simple-icons/    # SVG payloads exported from Shields.io/Simple Icons badge renders
├── fallback/        # Non-official placeholders for unresolved logo slugs
└── logo-manifest.json
```

## How These Are Used

AWS and Azure provider badges use custom `logo=data:image/svg+xml;base64,...` payloads because named Shields/Simple Icons slugs have not rendered consistently for those providers. Their editable SVG sources live in `custom/`.

Most other logos are exported from Shields.io-rendered badges that use Simple Icons slugs, such as `logo=python`, `logo=terraform`, or `logo=googlecloud`. Those exported SVGs live in `simple-icons/`.

If a referenced slug does not resolve through Shields.io or the Simple Icons CDN, this library creates a non-official placeholder in `fallback/`. Fallback SVGs are intentionally plain and should be replaced with approved artwork before being used as branded logos.

## Export Coverage

- Referenced logo parameters: 238
- Saved SVG logos: 205
- Local fallback placeholders: 33
- Failed exports: 0

See `logo-manifest.json` for source parameters, local file paths, and resolution status.

## Maintenance Workflow

1. Edit or replace the local SVG source.
2. Base64 encode the SVG.
3. URL encode the full `data:image/svg+xml;base64,...` value.
4. Place the encoded value in the Shields.io `logo=` query parameter.
5. Validate the badge URL renders and contains an embedded `<image>` element.

## References

- [Shields.io Static Badges](https://shields.io/docs/static-badges)
- [Shields.io Logos](https://shields.io/docs/logos)
- [Simple Icons](https://simpleicons.org/)
