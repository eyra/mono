defmodule Systems.Account.SignupPage do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.User, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Uri, __MODULE__})
  on_mount({Frameworks.GreenLight.LiveHook, __MODULE__})
  on_mount({Frameworks.Fabric.LiveHook, __MODULE__})

  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  alias Systems.Account
  alias Systems.Account.UserForm
  alias Systems.Account.User
  alias Frameworks.Utility.Params
  alias Frameworks.Signal

  @impl true
  def mount(%{"user_type" => user_type} = params, _session, socket) do
    require_feature(:password_sign_in)
    creator? = user_type == "creator"
    post_signup_action = Params.parse_string_param(params, "post_signup_action")
    changeset = Account.Public.change_user_registration(%User{})

    {
      :ok,
      socket
      |> assign(
        creator?: creator?,
        post_signup_action: post_signup_action,
        privacy_policy_accepted: false,
        privacy_policy_error: nil,
        changeset: changeset,
        active_menu_item: nil
      )
      |> update_menus()
    }
  end

  def update_menus(%{assigns: %{current_user: user, uri: uri}} = socket) do
    menus = build_menus(stripped_menus_config(), user, uri)
    assign(socket, menus: menus)
  end

  @impl true
  def handle_event(
        "signup",
        %{"user" => user_params},
        %{
          assigns: %{
            post_signup_action: post_signup_action,
            creator?: creator?,
            privacy_policy_accepted: privacy_policy_accepted
          }
        } = socket
      ) do
    user_params = Map.put(user_params, "creator", creator?)

    with :ok <-
           validate_privacy_policy(post_signup_action == "add_to_panl", privacy_policy_accepted),
         {:ok, user} <- Account.Public.register_user(user_params) do
      handle_successful_registration(socket, user)
    else
      {:error, :privacy_policy_not_accepted} ->
        handle_privacy_policy_error(socket)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Account.Public.change_user_registration(%User{}, attrs)

    {:noreply,
     socket
     |> assign(changeset: changeset, privacy_policy_error: nil)}
  end

  @impl true
  def handle_event("toggle", %{"checkbox" => field}, socket) do
    current_value = Map.get(socket.assigns, :privacy_policy_accepted, false)
    new_value = !current_value

    {:noreply,
     socket
     |> assign(privacy_policy_accepted: new_value)}
  end

  defp validate_privacy_policy(show_privacy_policy?, privacy_policy_accepted) do
    if show_privacy_policy? and not privacy_policy_accepted do
      {:error, :privacy_policy_not_accepted}
    else
      :ok
    end
  end

  defp handle_privacy_policy_error(socket) do
    {:noreply,
     socket
     |> assign(
       privacy_policy_accepted: false,
       privacy_policy_error: dgettext("eyra-account", "privacy.policy.must.be.accepted")
     )}
  end

  defp handle_successful_registration(socket, user) do
    if socket.assigns.post_signup_action do
      Signal.Public.dispatch({:account, :post_signup}, %{
        user: user,
        action: socket.assigns.post_signup_action
      })
    end

    {:ok, _} =
      Account.Public.deliver_user_confirmation_instructions(
        user,
        &url(socket, ~p"/user/confirm/#{&1}")
      )

    {:noreply,
     socket
     |> put_flash(:info, dgettext("eyra-user", "account.created.successfully"))
     |> push_navigate(to: ~p"/user/await-confirmation")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.stripped menus={@menus}>
      <div id="signup_content" phx-hook="LiveContent" data-show-errors={true}>
        <Area.content>
        <Margin.y id={:page_top} />
        <Area.form>
          <Text.title2><%= dgettext("eyra-account", "signup.title") %></Text.title2>
          <UserForm.password_signup
            changeset={@changeset}
            privacy_policy_visible={@post_signup_action == "add_to_panl"}
            privacy_policy_error={@privacy_policy_error}
          />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
