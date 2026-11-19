defmodule Next.Config.BundleConfigTest do
  # BUNDLE picks the SaaS (config/config.exs). Mix doesn't see a change of
  # BUNDLE, so a module that reads config at compile time keeps the value of the
  # previous build; a release or `mix run` then refuses to start. So BUNDLE may
  # only change config that is read at runtime, and both SaaS endpoints, whose
  # config Phoenix reads at compile time, are configured in every build.
  # Sets BUNDLE while config/config.exs is evaluated.
  use ExUnit.Case, async: false

  @endpoints [NextWeb.Endpoint, MicaSaasWeb.Endpoint]

  setup do
    saved = System.get_env("BUNDLE")

    on_exit(fn ->
      if saved, do: System.put_env("BUNDLE", saved), else: System.delete_env("BUNDLE")
    end)
  end

  defp config(bundle, env) do
    System.put_env("BUNDLE", bundle)
    Config.Reader.read!("config/config.exs", env: env, target: :host)[:mica]
  end

  for env <- [:dev, :test, :prod] do
    test "both endpoints have the same config whichever BUNDLE picks, in #{env}" do
      next = config("next", unquote(env))
      self = config("self", unquote(env))

      for endpoint <- @endpoints do
        assert next[endpoint], "#{inspect(endpoint)} is not configured in the Next build"
        # Inspected, so that the live-reload patterns compare by their source.
        assert inspect(next[endpoint]) == inspect(self[endpoint])
      end
    end

    test "BUNDLE changes only the SaaS, its account methods and its pool assets, in #{env}" do
      next = config("next", unquote(env))
      self = config("self", unquote(env))

      changed =
        for key <- Enum.uniq(Keyword.keys(next) ++ Keyword.keys(self)),
            inspect(next[key]) != inspect(self[key]),
            do: key

      assert changed -- [:account, :pixel, :saas] == []
    end
  end
end
