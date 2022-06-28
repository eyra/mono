defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :studentpool
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent}

  alias Systems.{
    Email
  }

  data(tabs, :any)
  data(initial_tab, :any)
  data(email_dialog, :map)

  @impl true
  def mount(%{"tab" => initial_tab}, _session, socket) do
    IO.puts("MOUNT")

    model = %{id: :sbe_2021, director: :pool}

    {
      :ok,
      socket
      |> assign(
        model: model,
        initial_tab: initial_tab,
        email_dialog: nil
      )
      |> assign_viewport()
      |> assign_breakpoint()
      |> observe_view_model()
      |> update_menus()
    }
  end

  @impl true
  def mount(_params, session, socket) do
    mount(%{"tab" => nil}, session, socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
    IO.puts("handle_view_model_updated")
    socket |> update_menus()
  end

  @impl true
  def handle_event("close_email_dialog", _, socket) do
    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info({:email_dialog, %Systems.Email.Model{} = email}, socket) do
    Email.Context.deliver_later!(email)

    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info({:email_dialog, :close}, socket) do
    {
      :noreply,
      socket
      |> close_email_dialog()
    }
  end

  def handle_info(
        {:email_dialog, %{recipients: recipients}},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    {
      :noreply,
      socket
      |> assign(
        email_dialog: %{
          id: :email_dialog,
          users: recipients,
          current_user: current_user
        }
      )
    }
  end

  def handle_info({:claim_focus, :email_form}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_resize(socket) do
    socket
    |> update_menus()
  end

  defp close_email_dialog(socket) do
    socket
    |> assign(email_dialog: nil)
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-studentpool", "title")} menus={@menus}>
      <div
        :if={@email_dialog}
        class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
        phx-click="close_email_dialog"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <Email.Dialog {...@email_dialog} />
        </div>
      </div>

      <div id={:pool_overview} phx-hook="ViewportResize">
        <TabbarArea tabs={@vm.tabs}>
          <ActionBar>
            <Tabbar vm={%{initial_tab: @initial_tab, size: :wide, type: :segmented}} />
          </ActionBar>
          <TabbarContent />
        </TabbarArea>
      </div>
    </Workspace>
    """
  end
end
