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

  @privacy_assignments %{
    "next_privacy_policy_accepted" => %{
      accepted_key: :next_privacy_policy_accepted,
      error_key: :next_privacy_policy_error
    },
    "panl_privacy_policy_accepted" => %{
      accepted_key: :panl_privacy_policy_accepted,
      error_key: :panl_privacy_policy_error
    }
  }

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
        next_privacy_policy_accepted: false,
        next_privacy_policy_error: nil,
        panl_privacy_policy_accepted: false,
        panl_privacy_policy_error: nil,
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
        %{assigns: assigns} = socket
      ) do
    user_params = Map.put(user_params, "creator", assigns.creator?)

    with :ok <- validate_privacy_policies(assigns),
         {:ok, user} <- Account.Public.register_user(user_params) do
      handle_successful_registration(socket, user)
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, error_type} ->
        handle_privacy_error(socket, error_type)
    end
  end

  @impl true
  def handle_event("form_change", %{"user" => attrs}, socket) do
    changeset = Account.Public.change_user_registration(%User{}, attrs)

    {:noreply,
     socket
     |> assign(
       changeset: changeset,
       next_privacy_policy_error: nil,
       panl_privacy_policy_error: nil
     )}
  end

  @impl true
  def handle_info(
        {"active_item_ids", %{active_item_ids: active_item_ids} = payload},
        socket
      ) do
    normalized_ids = normalize_ids(active_item_ids)
    component_id = component_id_from_payload(payload)

    socket = maybe_assign_privacy_component(socket, component_id, normalized_ids)

    {:noreply, socket}
  end

  defp normalize_ids(ids) do
    ids
    |> List.wrap()
    |> Enum.map(&normalize_active_item_id/1)
  end

  defp normalize_active_item_id(id) when is_atom(id), do: Atom.to_string(id)
  defp normalize_active_item_id(id) when is_binary(id), do: id
  defp normalize_active_item_id(id), do: to_string(id)

  defp component_id_from_payload(payload) do
    payload
    |> Map.get(:current_items, [])
    |> List.wrap()
    |> Enum.find_value(&extract_component_id/1)
  end

  defp extract_component_id(%{id: id}) when not is_nil(id), do: normalize_active_item_id(id)
  defp extract_component_id(_), do: nil

  defp maybe_assign_privacy_component(socket, nil, _normalized_ids), do: socket

  defp maybe_assign_privacy_component(socket, component_id, normalized_ids) do
    case Map.fetch(@privacy_assignments, component_id) do
      {:ok, %{accepted_key: accepted_key, error_key: error_key}} ->
        accepted? = component_id in normalized_ids

        socket
        |> assign(accepted_key, accepted?)
        |> assign(error_key, nil)

      :error ->
        socket
    end
  end

  defp validate_privacy_policies(%{
         post_signup_action: post_signup_action,
         panl_privacy_policy_accepted: panl_privacy_policy_accepted,
         next_privacy_policy_accepted: next_privacy_policy_accepted
       }) do
    cond do
      post_signup_action == "add_to_panl" and not panl_privacy_policy_accepted ->
        {:error, :panl_privacy_policy_not_accepted}

      not next_privacy_policy_accepted ->
        {:error, :next_privacy_policy_not_accepted}

      true ->
        :ok
    end
  end

  defp handle_privacy_error(socket, :next_privacy_policy_not_accepted) do
    {:noreply,
     assign(socket,
       next_privacy_policy_accepted: false,
       next_privacy_policy_error: dgettext("eyra-account", "privacy.next-policy.required")
     )}
  end

  defp handle_privacy_error(socket, :panl_privacy_policy_not_accepted) do
    {:noreply,
     assign(socket,
       panl_privacy_policy_accepted: false,
       panl_privacy_policy_error: dgettext("eyra-account", "panl.privacy.policy.required")
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
            next_privacy_policy_accepted={@next_privacy_policy_accepted}
            next_privacy_policy_error={@next_privacy_policy_error}
            panl_privacy_policy_visible={@post_signup_action == "add_to_panl"}
            panl_privacy_policy_accepted={@panl_privacy_policy_accepted}
            panl_privacy_policy_error={@panl_privacy_policy_error}
          />
        </Area.form>
        </Area.content>
      </div>
    </.stripped>
    """
  end
end
