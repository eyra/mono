defmodule Self.Account.SigninPage do
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias Systems.Account.User
  alias Systems.Account.UserForm

  @impl true
  def mount(params, _session, socket) do
    require_feature(:password_sign_in)

    {
      :ok,
      socket
      |> assign(email: Map.get(params, "email"))
      |> update_form()
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  defp update_form(%{assigns: %{email: nil}} = socket) do
    assign(socket, :form, to_form(%{}))
  end

  defp update_form(%{assigns: %{email: email}} = socket) when is_binary(email) do
    attrs =
      if User.valid_email?(email) do
        %{"email" => email}
      else
        %{}
      end

    assign(socket, :form, to_form(attrs))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "signin.title") %></Text.title2>
          <div>
            <UserForm.password_signin for={@form} user_type={:participant} />
          </div>
          <.spacing value="M" />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
