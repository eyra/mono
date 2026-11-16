defmodule Mica.Test.SandboxLogFilter do
  @moduledoc """
  Drops the benign SQL sandbox teardown disconnect logs that appear during the
  test suite.

  When a test process (the sandbox connection owner) exits while a process it
  spawned is still running a query — typically a LiveView re-rendering, or
  Ecto's parallel preloader (`maybe_pmap`) running association fetches in
  `Task.async_stream` — DBConnection logs an `owner #PID<...> exited` /
  `Client #PID<...> is still using a connection from owner` error. The
  transaction is rolled back by the sandbox; the message is teardown-timing
  noise, not a real failure.

  This filter is intentionally narrow: a genuine in-test database failure
  surfaces as a `Postgrex.Error` (a SQL error), which does not match the
  signature below and is left untouched.
  """

  def filter(log_event, _extra) do
    if sandbox_teardown?(log_event), do: :stop, else: :ignore
  end

  defp sandbox_teardown?(%{msg: msg}) do
    text = message_text(msg)

    String.contains?(text, "still using a connection from owner") or
      (String.contains?(text, "owner #PID") and String.contains?(text, "exited"))
  end

  defp sandbox_teardown?(_log_event), do: false

  defp message_text({:string, chardata}), do: safe_chardata(chardata)
  defp message_text({:report, report}), do: inspect(report)

  defp message_text({format, args}) when is_list(format) and is_list(args) do
    safe_chardata(:io_lib.format(format, args))
  end

  defp message_text(other), do: inspect(other)

  defp safe_chardata(chardata) do
    IO.chardata_to_string(chardata)
  rescue
    _ -> inspect(chardata)
  end
end
