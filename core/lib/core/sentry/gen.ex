defmodule Core.Sentry.Gen do
  alias Sentry.Config
  require Logger

  defp print(message) do
    Logger.notice(message)
  end

  @moduledoc """
  Sends a test event to Sentry to check if your Sentry configuration is correct.

  This task reports a `RuntimeError` exception like this one:

      %RuntimeError{message: "Testing sending Sentry event"}

  ## Options

    * `compile` - boolean, use to does not compile, even if files require compilation.
    * `type` - `exception` or `message`. Defaults to `exception`. *Available since v10.1.0.*.
    * `stacktrace` - does not include a stacktrace in the reported event. *Available since
      v10.1.0.*.

  """

  def test_event() do
    print_environment_info()

    if Config.dsn() do
      send_event()
    else
      print("Event not sent because the :dsn option is not set (or set to nil)")
    end
  end

  defp print_environment_info do
    print("Client configuration:")

    if dsn = Config.dsn() do
      print("server: #{dsn.endpoint_uri}")
      print("public_key: #{dsn.public_key}")
      print("secret_key: #{dsn.secret_key}")
    end

    print("current environment_name: #{inspect(to_string(Config.environment_name()))}")
    print("hackney_opts: #{inspect(Config.hackney_opts())}\n")
  end

  defp send_event() do
    {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

    print("Sending test event...")

    exception = %RuntimeError{message: "Testing sending Sentry event"}
    result = Sentry.capture_exception(exception, result: :sync, stacktrace: stacktrace)

    case result do
      {:ok, id} ->
        print("Test event sent, event ID: #{id}")

      {:error, reason} ->
        print("Error sending event:\n\n#{inspect(reason)}")

      :excluded ->
        print("No test event was sent because the event was excluded by a filter")

      :unsampled ->
        print("""
        No test event was sent because the event was excluded according to the :sample_rate \
        configuration option.
        """)
    end
  end
end
