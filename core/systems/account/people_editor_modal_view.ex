defmodule Systems.Account.PeopleEditorModalView do
  @moduledoc """
  Modal LiveView for managing people (add/remove).

  Wraps PeopleEditorComponent in a modal context.

  ## Session params
  - `title` - The modal title
  - `people` - List of current people (users with :profile preloaded)
  - `users` - List of available users to add (users with :profile preloaded)
  - `current_user` - The current user (for self-removal confirmation)

  ## Callbacks
  Override `handle_add_user/2` and `handle_remove_user/2` in the parent
  to persist changes.
  """
  use CoreWeb, :modal_live_view

  alias Systems.Account

  @callback handle_add_user(user :: Account.User.t(), socket :: Phoenix.LiveView.Socket.t()) ::
              Phoenix.LiveView.Socket.t()

  @callback handle_remove_user(user :: Account.User.t(), socket :: Phoenix.LiveView.Socket.t()) ::
              Phoenix.LiveView.Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Systems.Account.PeopleEditorModalView

      use CoreWeb, :modal_live_view

      alias Systems.Account

      @impl true
      def mount(:not_mounted_at_router, _session, socket) do
        {:ok, socket}
      end

      @impl true
      def handle_info({:add_user, %{user: user}}, socket) do
        {:noreply, handle_add_user(user, socket)}
      end

      @impl true
      def handle_info({:remove_user, %{user: user}}, socket) do
        {:noreply, handle_remove_user(user, socket)}
      end

      @impl true
      def render(assigns) do
        ~H"""
        <div data-testid="people-modal">
          <.live_component
            module={Account.PeopleEditorComponent}
            id="people_editor"
            title={@vm.title}
            people={@vm.people}
            users={@vm.users}
            current_user={@current_user}
          />
        </div>
        """
      end

      defoverridable mount: 3, render: 1
    end
  end
end
