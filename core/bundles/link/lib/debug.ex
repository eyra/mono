defmodule Link.Debug do
  @moduledoc """
  The debug screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :debug
  alias CoreWeb.Router.Helpers, as: Routes

  alias CoreWeb.User.Forms.Debug, as: UserDebugForm
  alias Systems.Email.DebugForm, as: EmailDebugForm
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Button.DynamicButton

  alias Frameworks.Pixel.Container.{Wrap}
  alias Frameworks.Pixel.Text.Title2

  data(start_button, :map)

  def mount(_params, _session, socket) do
    start_button = %{
      action: %{
        type: :redirect,
        to: Routes.live_path(socket, Link.Onboarding.Wizard)
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

  def handle_event("save", _, socket) do
    {:noreply, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-ui", "debug.title")} menus={@menus}>
      <MarginY id={:page_top} />
      <ContentArea>
        <MarginY id={:page_top} />
        <Title2 margin="">Onboarding</Title2>
        <Spacing value="S" />
        <Wrap>
          <DynamicButton vm={@start_button} />
        </Wrap>
      </ContentArea>

      <Spacing value="XL" />
      <UserDebugForm id={:user_debug} user={@current_user} />
      <Spacing value="XL" />
      <EmailDebugForm id={:mail_debug} user={@current_user} />
    </Workspace>
    """
  end
end
