defmodule Frameworks.Signal.Context do
  @signal_handlers [
    Core.Accounts.SignalHandlers,
    Core.Pools.SignalHandlers,
    Core.Mailer.SignalHandlers,
    Core.WebPush.SignalHandlers,
    Core.APNS.SignalHandlers,
    Systems.Observatory.Switch,
    Systems.Assignment.Switch,
    Systems.Campaign.Switch,
    Systems.NextAction.Switch
  ]

  def dispatch(signal, message) do
    for handler <- signal_handlers() do
      handler.dispatch(signal, message)
    end

    :ok
  end

  def dispatch!(signal, message) do
    :ok = dispatch(signal, message)
  end

  @doc """
  Send a signal as part of an Ecto Multi.

  It automatically merges the message with the multi
  changes.
  """
  def multi_dispatch(multi, signal, message) when is_map(message) do
    Ecto.Multi.run(multi, :dispatch_signal, fn _, updates ->
      :ok = dispatch(signal, Map.merge(updates, message))
      {:ok, nil}
    end)
  end

  defp signal_handlers do
    Application.get_env(:core, :signal_handlers, []) ++
      @signal_handlers
  end
end
