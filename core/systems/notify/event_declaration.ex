defmodule Systems.Notify.EventDeclaration do
  @moduledoc """
  Per-system notification event registration, mirroring the `_routes.ex`
  convention. A system opts in by dropping a `_notify.ex`:

      defmodule Systems.Assignment.Notify do
        use Systems.Notify.EventDeclaration

        event(:contribution_accepted, channels: [:email, :na])
        event(:contribution_declined, channels: [:email, :na])
      end

  Then register the notifier module in application config so
  `Systems.Notify.EventType` finds it:

      config :core, Systems.Notify,
        notifiers: [Systems.Assignment.Notify, ...]

  Only systems that actually publish events need a `_notify.ex`; adding one
  later requires no changes elsewhere except a single line in that config
  list.
  """

  defmacro __using__(_opts) do
    quote do
      import Systems.Notify.EventDeclaration, only: [event: 2]

      Module.register_attribute(__MODULE__, :notify_events_acc, accumulate: true)
      @before_compile Systems.Notify.EventDeclaration
    end
  end

  defmacro event(type, opts) do
    quote do
      @notify_events_acc {unquote(type), unquote(opts)}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Returns the list of `{event_type, opts}` declared in this module. Used
      by `Systems.Notify.EventType` to build the global registry.
      """
      def notify_events, do: @notify_events_acc
    end
  end
end
