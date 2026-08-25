defmodule Systems.Account.IdentityProviderTransferController do
  use Phoenix.Controller, formats: [:html]
  use CoreWeb, :verified_routes

  import Plug.Conn

  alias Systems.Account
  alias Systems.Account.Identity

  def confirm(conn, %{"idp" => "mock"}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => "mock", "user_id" => user_id} ->
        user = Account.Public.get_user!(user_id)

        case Identity.remove_auth_methods(user) do
          {:ok, _} ->
            conn
            |> delete_session(:idp_transfer)
            |> Account.UserAuth.log_in_user(user, false)

          {:error, _step, _reason, _changes} ->
            conn |> send_resp(422, "Transfer failed") |> halt()
        end

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  def confirm(conn, %{"idp" => "apple"}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => "apple", "user_id" => user_id, "userinfo" => userinfo} ->
        user = Account.Public.get_user!(user_id)

        case Identity.transfer(Identity.Apple, :apple, user, userinfo) do
          {:ok, %{selected_identity: _}} ->
            conn
            |> delete_session(:idp_transfer)
            |> Account.UserAuth.log_in_user(user, false)

          {:error, _step, _reason, _changes} ->
            conn |> send_resp(422, "Transfer failed") |> halt()
        end

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  def confirm(conn, %{"idp" => "google"}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => "google", "user_id" => user_id, "userinfo" => userinfo} ->
        user = Account.Public.get_user!(user_id)

        case Identity.transfer(Identity.Google, :google, user, userinfo) do
          {:ok, %{selected_identity: _}} ->
            conn
            |> delete_session(:idp_transfer)
            |> Account.UserAuth.log_in_user(user, false)

          {:error, _step, _reason, _changes} ->
            conn |> send_resp(422, "Transfer failed") |> halt()
        end

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  def confirm(conn, %{"idp" => "surfconext"}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => "surfconext", "user_id" => user_id, "userinfo" => userinfo} ->
        user = Account.Public.get_user!(user_id)

        case Identity.transfer(Identity.Surfconext, :surfconext, user, userinfo) do
          {:ok, %{selected_identity: _}} ->
            conn
            |> delete_session(:idp_transfer)
            |> Account.UserAuth.log_in_user(user, false)

          {:error, _step, _reason, _changes} ->
            conn |> send_resp(422, "Transfer failed") |> halt()
        end

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  def decline(conn, %{"idp" => idp}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => ^idp} ->
        conn
        |> delete_session(:idp_transfer)
        |> redirect(to: ~p"/user/auth/identify")

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end
end
