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
      case result do
        :ok -> :ok
        _ -> acc
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
    Keyword.get(config(), :handlers, [])
    |> Enum.map(fn module_name ->
      String.to_atom("Elixir.#{module_name}")
    end)
  end

  defp config do
    Application.get_env(:core, :signal)
  end
end
