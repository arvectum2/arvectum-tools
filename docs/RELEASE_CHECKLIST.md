# Arvectum Tools — Release Checklist

Use this as the repository-level release gate. Product-specific store and compliance checklists remain authoritative when they are stricter.

## 1. Scope

- Product roadmap reflects the exact release scope.
- No unrelated feature has slipped into the release.
- Bundle/application ID, version and build number are product-specific and correct.

## 2. Quality

- Relevant path-scoped CI is green.
- Clean local release build succeeds.
- Core user job is verified on a real device when platform behavior matters.
- Upgrade from the previous public version is checked when applicable.
- No generated build products, credentials or local machine settings are tracked.

## 3. Privacy and permissions

- Permissions match the actual feature set.
- Privacy disclosure matches the shipped SDKs and data flows.
- Local-first behavior is preserved unless the product roadmap explicitly requires a backend.
- Analytics or advertising failure cannot block the core utility.

## 4. Monetization

- Product-specific advertising policy is followed; there is no family-wide default placement.
- Ads never impersonate product controls.
- Ad/network failure has a graceful no-ad path.
- Store declarations cover all advertising/analytics SDK behavior.

## 5. Store assets

- Store name, subtitle/short description and screenshots match the current product.
- Localized metadata is reviewed for meaning, not only literal translation.
- Privacy/support URLs resolve publicly.
- Release notes describe user-visible changes only.

## 6. Release

- Release commit is on the product's intended integration line.
- Tag format: `<product>/v<version>` for new releases unless an existing product convention requires otherwise.
- Signing/archive artifact is reproducible from tracked source plus protected credentials.
- Submission status and store build/version are recorded in the product docs.

## 7. Post-release

- Verify the live store page and install/update path.
- Verify the core job from the store-delivered build.
- Record crashes, reviews, conversion and product-specific success metrics.
- Put follow-up work in the product roadmap rather than expanding scope ad hoc.
