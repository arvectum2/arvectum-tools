# Arvectum Tools — non-negotiable release gate

Every app in this repository (Pushkin, Ухват, ChickMark, Фото/PDF and future products) requires the **owner's explicit, per-release approval in the current conversation** BEFORE any external release action, including:

- uploading a build to App Store Connect, TestFlight, Transporter or `altool`;
- creating, modifying or submitting an App Review submission;
- enabling external beta distribution, publication, or release;
- changing a live listing or its metadata unless expressly approved for that exact change.

"Делай", "продолжай", "доделай", a green CI run, a signed IPA, a previous release authorization, or an authorization for QA are **not** approval to send to Apple. Do not assume approval from prior discussions. Work in branches, compile, test, verify and prepare release notes; stop at the explicit release gate and ask before any upload/submission.

When the owner approves a release, configure **automatic availability after Apple approval** (`AFTER_APPROVAL`), not manual (`MANUAL`), unless the owner explicitly changes that preference. Submission and automatic publication are still separate from QA. Do not press a release button, submit a beta, or use direct ASC API outside explicit release consent.

For physical QA, never uninstall personal applications, reset history, overwrite existing iOS Shortcuts automations, or delete Apple Health samples outside a precisely scoped QA-only record created and owned by the disposable QA app. Prefer separate bundle IDs and a non-destructive test-data ledger.

As of 19 October 2026, Pushkin 1.0.1(4) was submitted prematurely and then explicitly withdrawn: review submission `COMPLETE`, version `DEVELOPER_REJECTED`, `releaseType=AFTER_APPROVAL`. **Do not resubmit without a new explicit permission.** The only public version is 1.0.
