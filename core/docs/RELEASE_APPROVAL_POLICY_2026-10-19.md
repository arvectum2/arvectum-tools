# Approval is mandatory before any Arvectum Tools App Store submission

**Owner decision 19.10.2026:** finish every requested task, perform real-device acceptance, present the exact build/version, outstanding known issues, and ask for explicit approval. Do not upload, submit, re-submit, schedule or publish to Apple absent a clear, current authorization for that version.

Approved distribution behavior for a release, once the owner has separately authorized its submission: **automatic public availability after Apple approval** (`releaseType: AFTER_APPROVAL`), no manual second step.

The accidentally submitted Pushkin 1.0.1(4) was canceled via Apple's reviewSubmissions API (`PATCH canceled=true`); confirmed review state `COMPLETE`, appStoreVersion state `DEVELOPER_REJECTED`. Automatic-release setting has been recorded while **not** under review. Existing public Pushkin 1.0 remains unchanged. Future work is solely internal QA until approval.

See the repository root [AGENTS.md](../../AGENTS.md) for enforcement across all app teams, automations, CI agents, QA and external tooling.

## Required release checklist

- [ ] Physical and CI tests complete with evidence linked in the app roadmap.
- [ ] Known open bugs, coverage gaps, migration risks and workarounds disclosed.
- [ ] Non-destructive device migration QA, and any user-data risks characterized.
- [ ] Exact source commit, release version, build, IPA hash and Store metadata prepared.
- [ ] Owner **explicitly authorizes submitting this exact build**.
- [ ] Only then upload and submit; automatic publish after approval, with no manual-release hold unless requested.
