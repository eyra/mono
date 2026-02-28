defmodule Next.Account.SigninPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  import Frameworks.Pixel.Line

  alias Frameworks.Pixel.Tabbed
  alias Next.Account.SigninPageBuilder
  alias Frameworks.Utility.Params

  @impl true
  def mount(params, _session, socket) do
    user_type = Map.get(params, "user_type", "participant")
    initial_tab = Map.get(params, "tab", user_type)
    tabbar_id = "account_signin"
    registration_status = Map.get(params, "status", nil)
    post_signin_action = Params.parse_string_param(params, "post_signin_action")

    {
      :ok,
      socket
      |> assign(
        email: Map.get(params, "email"),
        user_type: user_type,
        initial_tab: initial_tab,
        tabbar_id: tabbar_id,
        show_errors: true,
        status: registration_status,
        post_signin_action: post_signin_action
      )
      |> update_view_model()
      |> update_menus()
    }
  end

  def update_view_model(socket) do
    vm = SigninPageBuilder.view_model(nil, socket.assigns)
    assign(socket, vm: vm)
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
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
          <Tabbed.bar id={@tabbar_id} tabs={@vm.tabs} initial_tab={@initial_tab} type={:segmented} size={:full} />
          <.spacing value="M" />
          <.line />


          <.spacing value="M" />
          <div id="live_content" phx-hook="LiveContent" data-show-errors={@show_errors}>
            <Tabbed.content socket={@socket} tabs={@vm.tabs} bar_id={@tabbar_id} />
          </div>
        </Area.form>
      </div>
    </.stripped>
    """
  end
end
