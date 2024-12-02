defmodule Frameworks.Signal.Public do
  require Logger

  import Frameworks.Utility.PrettyPrint

  # FIXME: move this registration outside of framework
  @signal_handlers [
    "Core.APNS.SignalHandlers",
    "Core.Mailer.SignalHandlers",
    "Core.WebPush.SignalHandlers",
    "Systems.Account.Switch",
    "Systems.Admin.Switch",
    "Systems.Advert.Switch",
    "Systems.Assignment.Switch",
    "Systems.Consent.Switch",
    "Systems.Crew.Switch",
    "Systems.Graphite.Switch",
    "Systems.Instruction.Switch",
    "Systems.NextAction.Switch",
    "Systems.Observatory.Switch",
    "Systems.Onyx.Switch",
    "Systems.Pool.Switch",
    "Systems.Project.Switch",
    "Systems.Storage.Switch",
    "Systems.Student.Switch",
    "Systems.Workflow.Switch"
  ]

  def dispatch(signal, message) do
    message = Map.put_new(message, :from_pid, self())

    Logger.notice(
      "SIGNAL: #{pretty_print(signal)} => #{pretty_print(Map.keys(message))}, FROM: #{inspect(Map.get(message, :from_pid))}",
      ansi_color: :blue
    )

    results = Enum.map(signal_handlers(), & &1.intercept(signal, message))

    if not Enum.member?(results, :ok) do
      Logger.warn(
        "Unhandeld signal: #{pretty_print(signal)} => #{pretty_print(Map.keys(message))}, FROM: #{inspect(Map.get(message, :from_pid))}"
      )
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
  def multi_dispatch(multi, signal, message \\ %{}) when is_map(message) do
    Ecto.Multi.run(multi, :dispatch_signal, fn _, updates ->
      :ok = dispatch(signal, Map.merge(updates, message))
      {:ok, message}
    end)
  end

  defp signal_handlers do
    (Application.get_env(:core, :signal_handlers, []) ++
       @signal_handlers)
    |> Enum.map(fn module_name -> String.to_atom("Elixir.#{module_name}") end)
  end
end
