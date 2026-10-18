# ld-ios-encode-poc

Minimal reproduction for a LaunchDarkly iOS SDK context-encoding issue, used as the PoC in a bug report.

It builds the released SDK (`launchdarkly/ios-client-sdk` 11.7.0) and encodes three local test contexts:

- Scenario 0 (sanity): the private attribute is correctly redacted.
- Scenario 1: an attribute named `/ssn` collides with a private sibling attribute `ssn`.
- Scenario 2: an attribute named `/name` collides with the private built-in `name`.

Scenarios 1 and 2 print `[LEAK]` when the value of the private attribute is present in the encoded output.

## Run

- On a Mac: `swift run poc`
- On GitHub: the included workflow (`.github/workflows/run-poc.yml`) runs it on a macOS runner on every push. Open the "Actions" tab and read the "Build and run PoC" step.

No LaunchDarkly account is needed and this never contacts LaunchDarkly servers.
