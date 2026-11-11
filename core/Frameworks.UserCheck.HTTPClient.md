# `Frameworks.UserCheck.HTTPClient`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_check/http_client.ex#L1)

Real HTTP client for the UserCheck email validation API.

Calls `GET https://api.usercheck.com/email/{email}` with Bearer auth.
Configured via application config:

    config :mica, Frameworks.UserCheck,
      client: Frameworks.UserCheck.HTTPClient,
      api_key: "your_api_key",
      base_url: "https://api.usercheck.com",
      timeout: 2_000

---

*Consult [api-reference.md](api-reference.md) for complete listing*
