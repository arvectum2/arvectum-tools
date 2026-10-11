# Arvectum Design Tokens

`ArvectumPalette.swift` contains the identical brand-level `Color` constants shared by multiple iOS applications. XcodeGen includes this **single source file** into the app targets; no separate copies or binary packages are required. App-specific colors, localizations, typography and views remain in their owning app.

When updating the palette, validate all three consumer builds and the Core architecture check.
