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

  defp signal_handlers do
    # Allow per-process override of signal handlers (useful for testing)
    handlers =
      case Process.get(:signal_handlers_override) do
        nil -> Keyword.get(config(), :handlers, [])
        override_handlers -> override_handlers
      end

    handlers
    |> Enum.map(fn module_name ->
      String.to_atom("Elixir.#{module_name}")
    end)
  end

  defp config do
    Application.get_env(:core, :signal)
  end
end
