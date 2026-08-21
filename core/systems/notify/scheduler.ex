defmodule Systems.Notify.Scheduler do
  @moduledoc """
  Decides when + how an event turns into messages.

  v1 is trivial: schedule = dispatch now. The abstraction is here so that later
  work (batching windows, quiet-hours, throttling, user preferences) plugs in
  as rule modules without touching event producers.
  """

  alias Systems.Notify.Dispatcher
  alias Systems.Notify.EventModel

  @doc """
  Schedule an event for delivery. In v1 dispatches immediately; future
  revisions will consult rules (event type, recipient state, time) to decide
  channels + timing + batching.
  """
  def schedule(%EventModel{} = event) do
    Dispatcher.dispatch(event)
  end
end
