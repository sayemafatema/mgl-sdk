# Fleet SDK — UI parity checklist (native cores vs reference hosts)

Reference implementations for behaviour and copy:

| Area | Flutter reference | Angular reference |
|------|-------------------|-------------------|
| Flow shell | [`flutter-sdk/lib/src/fleet_flow_screen.dart`](../../flutter-sdk/lib/src/fleet_flow_screen.dart) | [`angular-sdk/src/lib/fleet-flow-host.component.ts`](../../angular-sdk/src/lib/fleet-flow-host.component.ts) |

Contract for HTTP payloads:

| Artifact | Path |
|----------|------|
| OpenAPI 3.1 | [`docs/openapi/fleet-api.yaml`](../openapi/fleet-api.yaml) |

## Screen / state parity (implement on Kotlin + Swift)

Mark **Done** per platform when UX matches acceptance criteria (copy may vary slightly).

| Step | ID | Acceptance |
|------|-----|------------|
| Mobile login | `auth_mobile` | 10-digit validation; navigate to OTP |
| OTP verify | `auth_otp` | Demo OTP `123456` in mock mode |
| PIN entry | `auth_pin` | Demo PIN `123456`; lockout messaging if applicable |
| Invite signup | `auth_invite` | Optional branch; demo codes `ABC123` / `XYZ789` |
| Driver shell tabs | `shell_tabs` | Primary tabs visible (Card / Scan / Assign / Txns / Profile — mirror reference) |
| Scan flow | `shell_scan` | Vehicle selection → authorize simulation |
| Profile / logout | `shell_profile` | Log out returns to login |

## Mock vs live API

| Mode | Behaviour |
|------|-----------|
| `useMock: true` | No network; bundled fixtures mirror TS [`core-sdk/services/mock-data.ts`](../../core-sdk/services/mock-data.ts) semantics |
| `useMock: false` | Bearer token + [`fleet-api.yaml`](../openapi/fleet-api.yaml) endpoints |

## Versioning note

Bump native artifact semver together when parity checklist rows change completion status for shipped flows.
