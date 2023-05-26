defmodule Link.Debug.Page do
  @moduledoc """
  The debug screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :debug
  alias CoreWeb.Router.Helpers, as: Routes

  alias CoreWeb.User
  alias Systems.Email
  import CoreWeb.Layouts.Workspace.Component

  def mount(_params, _session, socket) do
    start_button = %{
      action: %{
        type: :redirect,
        to: Routes.live_path(socket, Link.Onboarding.WizardPage)
      },
      face: %{
        type: :primary,
        label: "Start onboarding flow"
      }
    }

    {
      :ok,
      socket
      |> assign(
        start_button: start_button,
        changesets: %{}
      )
      |> update_menus()
    }
  end

  @impl true
  def handle_event("save", _, socket) do
    {:noreply, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("link-ui", "debug.title")} menus={@menus}>
      <Margin.y id={:page_top} />
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2 margin="">Onboarding</Text.title2>
        <.spacing value="S" />
        <.wrap>
          <Button.dynamic {@start_button} />
        </.wrap>
      </Area.content>

      <.spacing value="XL" />
      <.live_component module={User.Forms.Debug} id={:user_debug} user={@current_user} />
      <.spacing value="XL" />
      <.live_component module={Email.DebugForm} id={:mail_debug} user={@current_user} />
    </.workspace>
    """
  end
end
