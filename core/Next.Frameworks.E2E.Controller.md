# `Next.Frameworks.E2E.Controller`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/e2e/controller.ex#L1)

API endpoint for E2E test fixture setup.

Creates test users and assignments needed for E2E tests.
Only available when the :e2e feature is enabled via ENABLED_APP_FEATURES.

POST /api/e2e/setup
Requires authenticated service account session.

Returns:
{
  "researcher_email": "e2e-researcher@eyra.co",
  "researcher_password": "...",
  "participant_email": "e2e-participant@eyra.co",
  "participant_password": "...",
  "donate_assignment_path": "/a/xyz123",
  "pdf_assignment_path": "/a/pdf123"
}

# `activate_user`

Directly activates a user account by email. Only available when :e2e feature is enabled.
Bypasses the email confirmation flow so E2E tests don't need to read from /sent_emails.

# `auth_module`

# `bootstrap`

Bootstrap endpoint - creates the E2E service user.
No authentication required, but only works when :e2e feature is enabled.
Call this once before running E2E tests.

# `print_auth_roles`

# `setup`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
