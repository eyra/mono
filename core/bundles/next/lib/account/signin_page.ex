defmodule Next.Account.SigninPage do
  use CoreWeb, :live_view
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import Frameworks.Pixel.Line

  alias Frameworks.Pixel.Tabbar

  alias Next.Account.SigninPageBuilder

  @impl true
  def mount(params, _session, socket) do
    initial_tab = Map.get(params, "tab")
    tabbar_id = "account_signin"

    {
      :ok,
      socket
      |> assign(
        email: Map.get(params, "email"),
        initial_tab: initial_tab,
        tabbar_id: tabbar_id,
        show_errors: true
      )
      |> update_view_model()
      |> update_menus()
    }
  end

  defp update_view_model(socket) do
    vm = SigninPageBuilder.view_model(nil, socket.assigns)
    assign(socket, vm: vm)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.form>
          <Margin.y id={:page_top} />
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-account", "signin.title") %></Text.title2>
          <Tabbar.container id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} type={:segmented} size={:full} />
          <.spacing value="M" />
          <.line />
          <.spacing value="M" />
          <div id="tabbar_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbar.content include_top_margin={false} tabs={@vm.tabs} />
          </div>
        </Area.form>
      </div>
    </.stripped>
    """
  end
end
