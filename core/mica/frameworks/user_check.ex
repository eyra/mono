defmodule Frameworks.UserCheck do
  @moduledoc """
  Email validation framework wrapping the UserCheck API.

  Detects disposable, role, blocklisted, and undeliverable email addresses.
  Uses a behaviour-based client so the real HTTP client can be swapped for
  a mock in dev/test environments.

  ## Configuration

      # config.exs (default)
      config :core, Frameworks.UserCheck,
        client: Frameworks.UserCheck.HTTPClient,
        base_url: "https://api.usercheck.com",
        timeout: 2_000

      # dev.exs / test.exs
      config :core, Frameworks.UserCheck,
        client: Frameworks.UserCheck.MockClient

      # runtime.aws.exs / runtime.fly.exs
      config :core, Frameworks.UserCheck,
        api_key: System.get_env("USERCHECK_API_KEY")

  ## Usage

      case Frameworks.UserCheck.check_email("user@example.com") do
        {:ok, %ResultModel{disposable: true}} -> # reject
        {:ok, %ResultModel{}} -> # accept
        {:error, _reason} -> # fail open or closed, caller decides
      end
  """

  alias Frameworks.UserCheck.ResultModel

  @doc """
  Validates an email address via the configured UserCheck client.

  Returns `{:ok, %ResultModel{}}` on success or `{:error, reason}` on failure.
  The caller is responsible for deciding whether to fail open (accept) or
  fail closed (reject) when an error is returned.
  """
  @spec check_email(String.t()) :: {:ok, ResultModel.t()} | {:error, term()}
  def check_email(email) when is_binary(email) do
    client().check_email(email)
  end

  defp client do
    Application.get_env(:core, __MODULE__, [])
    |> Keyword.get(:client, Frameworks.UserCheck.HTTPClient)
  end
end
