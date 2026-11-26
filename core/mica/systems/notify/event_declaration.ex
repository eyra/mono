defmodule Systems.Notify.EventDeclaration do
  @moduledoc """
  Per-system notification event registration, mirroring the `_routes.ex`
  convention. A system opts in by dropping a `_notify.ex`:

      defmodule Systems.Assignment.Notify do
        use Systems.Notify.EventDeclaration

        event(:contribution_accepted, channels: [:email, :na])
        event(:contribution_declined, channels: [:email, :na])
      end

  Then list the notifier module in the system's `_system.ex` so
  `Systems.Notify.EventType` finds it:

      def notifiers, do: [Systems.Assignment.Notify]

  Only systems that actually publish events need a `_notify.ex`.

  An event on the `:na` (Actions) channel can name the next action it shows as
  (`Systems.NextAction.ViewModel`) and its priority; the channel then builds
  that next action from the event itself, keyed by its `correlation_id`, with
  its `metadata` as params:

      event(:license_reminder,
        channels: [:na],
        next_action: Systems.License.NextActions.Reminder,
        priority: :high
      )

  Its button opens the notification through `Systems.Notify.Public.open_action/2`,
  so a click marks it seen.
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
