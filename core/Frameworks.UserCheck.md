# `Frameworks.UserCheck`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/user_check.ex#L1)

Email validation framework wrapping the UserCheck API.

Detects disposable, role, blocklisted, and undeliverable email addresses.
Uses a behaviour-based client so the real HTTP client can be swapped for
a mock in dev/test environments.

## Configuration

    # config.exs (default)
    config :mica, Frameworks.UserCheck,
      client: Frameworks.UserCheck.HTTPClient,
      base_url: "https://api.usercheck.com",
      timeout: 2_000

    # dev.exs / test.exs
    config :mica, Frameworks.UserCheck,
      client: Frameworks.UserCheck.MockClient

    # runtime.exs
    config :mica, Frameworks.UserCheck,
      api_key: System.get_env("USERCHECK_API_KEY")

## Usage

    case Frameworks.UserCheck.check_email("user@example.com") do
      {:ok, %ResultModel{disposable: true}} -> # reject
      {:ok, %ResultModel{}} -> # accept
      {:error, _reason} -> # fail open or closed, caller decides
    end

# `check_email`

```elixir
@spec check_email(String.t()) ::
  {:ok, Frameworks.UserCheck.ResultModel.t()} | {:error, term()}
```

Validates an email address via the configured UserCheck client.

Returns `{:ok, %ResultModel{}}` on success or `{:error, reason}` on failure.
The caller is responsible for deciding whether to fail open (accept) or
fail closed (reject) when an error is returned.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
