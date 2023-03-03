defmodule Systems.Pool.DetailPage do
  @moduledoc """
   The pool details screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_detail
  use CoreWeb.UI.Responsive.Viewport

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.Navigation.{ActionBar, TabbarArea, Tabbar, TabbarContent}

  alias Systems.{
    Pool,
    Email
  }

  data(tabbar_id, :string)
  data(tabs, :any)
  data(initial_tab, :any)
  data(email_dialog, :map)
  data(title, :string, default: "")

  @impl true
  def mount(%{"id" => pool_id, "tab" => initial_tab}, _session, socket) do
    pool_id = String.to_integer(pool_id)
    model = Pool.Public.get!(pool_id)
    tabbar_id = "pool_detail/#{pool_id}"

    {
      :ok,
      socket
      |> assign(
        id: pool_id,
        tabbar_id: tabbar_id,
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
  def mount(%{"id" => pool_id}, session, socket) do
    mount(%{"id" => pool_id, "tab" => nil}, session, socket)
  end

  defoverridable handle_view_model_updated: 1

  def handle_view_model_updated(socket) do
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
    Email.Public.deliver_later!(email)

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
    <Workspace title={@vm.title} menus={@menus}>
      <div
        :if={@email_dialog}
        class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
        phx-click="close_email_dialog"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <Email.Dialog {...@email_dialog} />
        </div>
      </div>

      <div id={:pool_detail} phx-hook="ViewportResize">
        <TabbarArea tabs={@vm.tabs}>
          <ActionBar>
            <Tabbar id={@tabbar_id} initial_tab={@initial_tab} size={:wide} type={:segmented} />
          </ActionBar>
          <TabbarContent />
        </TabbarArea>
      </div>
    </Workspace>
    """
  end
end
