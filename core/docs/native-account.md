# Native Account session contract

The native Profile screen uses the same account and WebKit cookie session as
`/user/account`. All responses are JSON with `Cache-Control: no-store`. A missing
or revoked session returns 401. The client cannot select a user ID.

- `GET /user/account/native/profile` returns `profile`, the visible `tabs`, and
  `csrf_token`. Profile includes `fullname`, `displayname`, `title`, `photo_url`,
  `email`, and `creator`. Each tab has `id`, `title`, `native`, and `path`.
- `POST /user/account/native/profile` accepts `{"profile": {...}}`. Editable fields
  are `fullname` and `displayname`; creators may also change `title`. Other fields
  are ignored. The existing profile changeset and persister own validation and
  downstream signals. A successful write returns the refreshed snapshot; invalid
  values return 422 with `error` and field `errors`.
- `POST /user/account/native/photo` accepts `{"data": "<base64>"}` for a JPEG or PNG
  of at most 2,000,000 decoded bytes. It uses the existing content storage and
  profile persister. Success returns the refreshed snapshot, invalid input 422,
  and a storage error 503. The iOS client resizes/re-encodes selected photos.
- `DELETE /user/account/native/session` uses the existing sign-out function to
  revoke the session token, expire cookies, and disconnect LiveViews. It returns
  `{"signed_out": true}`. Later calls with that session return 401.

Every write sends the returned token in `x-csrf-token`; session cookies alone do
not authorize a write. Calls run through the existing same-origin WebKit fetch
transport, keeping cookies out of native application code.

The first native version implements Profile and sign out. Account navigation and
internal tab controls are native. Other permitted tabs use their existing web
content at the returned `path`; `navigation=external` tells the web Account page
to render only that tab without a second tab bar. Existing web URLs retain their
usual tab controls. Availability comes from the current account rules.

Core must be deployed before an iOS release that uses these endpoints.
