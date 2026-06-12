# CSV import — implementation notes

Companion to [`design-briefing.md`](design-briefing.md) §5. The briefing defines the contract; this file captures the implementation behavior — validation rules, UX flow, race-condition handling, error reporting.

## Flow

1. **Upload.** Operator clicks "Import participants" on an assignment, picks a CSV file.
2. **Validation.** Next parses and validates the file end-to-end (see [Validation](#validation)). If any row fails, the import is rejected with a per-row error list. **All-or-nothing — no partial application.**
3. **Confirmation dialog.** Next computes the diff against the current participant list (a snapshot at upload time) and shows a summary:
   > Importing this CSV will:
   > - Add **N** new participants
   > - Remove **M** participants
   > - Keep **K** participants who could not be removed because they have already started
   >
   > [Cancel] [Confirm import]
4. **Commit.** On confirm, Next applies the change inside a transaction. The "already started" check is **re-evaluated at commit time**, not at upload time — between the dialog being shown and the operator clicking Confirm, more participants may have started.
5. **Result summary.** After commit, Next shows what actually happened (which may differ from the preview if more participants started in the meantime).

## Validation

Rejected files (whole import fails):

- Missing required header column (`centerdata_sub` or `email`).
- Unknown extra columns.
- Any row with a missing/empty `centerdata_sub` or `email`.
- Any row with a malformed email (basic RFC 5322 shape).
- Duplicate `centerdata_sub` within the file.

`label` is optional and free-form; no validation beyond character encoding.

## User and Participant record semantics

- **User record** (one per `centerdata_sub`): identified by `centerdata_sub`; holds `email`. Either CSV import or OIDC sign-in may **create** this record. **Only OIDC sign-in updates it** — `email` is overwritten from the ID token. CSV import never touches an existing User record's fields.
- **Participant record** (one per user-per-assignment): membership row. Holds `user_id`, `assignment_id`, `label`, status. CSV import creates, updates (`label`), or removes these freely, subject to the started-protection rule.

The Crew model that Next uses internally to manage assignment membership is not exposed to operators — they only see "participants".

## Started-protection rule

A participant is **protected from removal** if they have engaged with the assignment after publication (concrete check: a participant session/state record exists). Otherwise they may be freely added or removed.

If a CSV omits a started participant, Next keeps them; the operator sees this in both the pre-commit preview and the post-commit summary.

## File format

RFC 4180 CSV, UTF-8 (with optional BOM tolerated), header row required, column order arbitrary, both LF and CRLF accepted on import.

## Auditing

Each import records who imported, when, file hash, the computed diff, and the actual applied diff (post-commit). Operators can review past imports per assignment.
