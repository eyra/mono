defmodule Core.Env do
  @moduledoc """
  The one place that names the OTP application whose config Mica reads.

  Code outside `config/` and tests reads and writes application config through
  this module instead of calling `Application.*_env(:core, ...)` directly, so
  renaming the application only changes `@app` here. The credo check
  `Credo.Check.Warning.CoreEnvAccess` enforces this.

  Compile-time reads use the `compile_env/2` macro, which keeps the release
  check that the value did not change between compile time and runtime:

      require Core.Env
      @policy_urls Core.Env.compile_env(:policy_urls)
  """

  @app :core

  def app, do: @app

  def get(key, default \\ nil), do: Application.get_env(@app, key, default)

  def fetch!(key), do: Application.fetch_env!(@app, key)

  def put(key, value), do: Application.put_env(@app, key, value)

  defmacro compile_env(key_or_path, default \\ nil) do
    quote do
      Application.compile_env(unquote(@app), unquote(key_or_path), unquote(default))
    end
  end
end
