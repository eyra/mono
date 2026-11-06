defmodule Frameworks.Signal.Private do
  import Frameworks.Utility.PrettyPrint

  require Logger

  def dispatch(signal, message) do
    Logger.info(
      "SIGNAL: #{pretty_print(signal)} => #{pretty_print(Map.keys(message))}, FROM: #{inspect(Map.get(message, :from_pid))}",
      ansi_color: :blue
    )

    signal_handlers()
    |> Enum.map(&dispatch(signal, message, &1))
    |> Enum.reduce({:error, :unhandled_signal}, fn result, acc ->
      case {result, acc} do
        # Success cases - signal was handled
        {:ok, _} ->
          :ok

        {_, :ok} ->
          :ok

        # Real errors (not unhandled) - these should fail the transaction
        {{:error, error}, _} when error != :unhandled_signal ->
          {:error, error}

        # Unhandled signal - keep accumulating to see if anyone handles it
        {{:error, :unhandled_signal}, _} ->
          acc

        # Any other return value
        {other, _} ->
          other
      end
    end)
  end

  def dispatch(signal, message, handler) do
    case handler.intercept(signal, message) do
      {:continue, key, value} ->
        dispatch({key, signal}, Map.put(message, key, value))

      other ->
        other
    end
  end

  # The SaaS's handlers, unless a test overrides them per process or with
  # `config :mica, :signal, handlers: [...]` (module names as atoms or strings).
  defp signal_handlers do
    case Process.get(:signal_handlers_override) || override_from_config() do
      nil -> Mica.SaaS.signal_handlers()
      handlers -> Enum.map(handlers, &Module.concat([&1]))
    end
  end

  defp override_from_config do
    Mica.Env.get(:signal, []) |> Keyword.get(:handlers)
  end
end
