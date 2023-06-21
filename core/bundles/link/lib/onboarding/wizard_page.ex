defmodule Link.Onboarding.WizardPage do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :onboarding

  import CoreWeb.Gettext

  alias Core.Accounts
  alias Link.Onboarding.WelcomeView, as: Welcome
  alias CoreWeb.User.Forms.Student, as: StudentForm
  alias CoreWeb.User.Forms.Features, as: FeaturesForm

  alias CoreWeb.UI.Tabbar
  alias Frameworks.Pixel.Button
  alias CoreWeb.UI.Navigation

  def mount(_params, _session, socket) do
    tabs = create_tabs(socket)
    tabbar_id = "onboarding"

    finish_button = %{
      action: %{
        type: :send,
        event: "finish"
      },
      face: %{
        type: :primary,
        label: dgettext("eyra-ui", "onboarding.forward")
      }
    }

    {
      :ok,
      socket
      |> assign(
        tabbar_id: tabbar_id,
        tabs: tabs,
        finish_button: finish_button,
        changesets: %{}
      )
      |> update_menus()
    }
  end

  @impl true
  def handle_event("finish", _, %{assigns: %{current_user: current_user}} = socket) do
    Accounts.mark_as_visited(current_user, :onboarding)
    {:noreply, push_redirect(socket, to: forward_path(socket))}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  defp append(list, extra, cond \\ true) do
    if cond, do: list ++ [extra], else: list
  end

  defp create_tabs(%{assigns: %{current_user: current_user}}) do
    []
    |> append(%{
      id: :welcome,
      title: dgettext("eyra-ui", "tabbar.item.welcome"),
      forward_title: dgettext("eyra-ui", "tabbar.item.welcome.forward"),
      live_component: Welcome,
      props: %{user: current_user},
      type: :sheet,
      active: true
    })
    |> append(
      %{
        id: :student,
        title: dgettext("eyra-ui", "tabbar.item.student"),
        forward_title: dgettext("eyra-ui", "tabbar.item.student.forward"),
        live_component: StudentForm,
        props: %{user: current_user},
        type: :form
      },
      current_user.student
    )
    |> append(%{
      id: :features,
      action: nil,
      title: dgettext("eyra-ui", "tabbar.item.features"),
      forward_title: dgettext("eyra-ui", "tabbar.item.features.forward"),
      live_component: FeaturesForm,
      props: %{user: current_user},
      type: :form
    })
  end

  defp forward_path(socket) do
    page = forward_page(socket)
    Routes.live_path(socket, page)
  end

  defp forward_page(%{assigns: %{current_user: %{researcher: true}}}), do: Link.Console.Page
  defp forward_page(_), do: Link.Marketplace.Page

  # data(tabbar_id, :string)
  # data(user_agent, :string, default: "")
  # data(current_user, :any)
  # data(tabs, :any)

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <Navigation.action_bar>
        <Tabbar.container id={@tabbar_id} tabs={@tabs} initial_tab={:welcome} />
      </Navigation.action_bar>
      <Tabbar.content tabs={@tabs} />
      <Tabbar.footer tabs={@tabs}>
        <Button.dynamic {@finish_button} />
      </Tabbar.footer>
    </.stripped>
    """
  end
end
