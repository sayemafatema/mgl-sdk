# UI screen mapping (React demo → native rebuilds)

The original Next.js demo mixed many screens into one file. After extraction, **logic** lives in `core-sdk`; **UI** is reimplemented per platform.

| Concern (from React demo) | Angular (this repo) | Flutter (your app) |
|----------------------------|--------------------|--------------------|
| FO driver table (`FODriversView`) | `DriverListComponent` + extend with `*ngFor` table styling | `ListView.separated` or `DataTable` |
| Driver row → detail | `(driverSelected)` output → route to detail with `driverId` | `Navigator.push` with `DriverDetailScreen` |
| Driver fields (name, VRN, status, balance) | `DriverDetailComponent` | `Column` / `ListTile` + formatting |
| Session / bindings / transactions / onboarding | **Not yet** in core SDK public API — extend OpenAPI + `FleetSDK` as you productize | Mirror new endpoints in `FleetApiService` |

Formatting:

- Amounts: API uses **paise** (`cardBalancePaise`). UI layers format to locale currency.
- Status chips: map `Active` / `Inactive` to Material / Cupertino styles.

No WebView is required: Angular templates and Flutter widgets bind to the same HTTP contract.
