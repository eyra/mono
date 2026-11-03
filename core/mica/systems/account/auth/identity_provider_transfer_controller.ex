defmodule Systems.Account.Auth.IdentityProviderTransferController do
  use Phoenix.Controller, formats: [:html]
  use MicaWeb, :verified_routes

  import Plug.Conn

  alias Systems.Account
  alias Systems.Account.Auth
  alias Systems.Account.SignInHandoff

  def confirm(conn, %{"idp" => "mock"}) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => "mock", "user_id" => user_id} ->
        user = Account.Public.get_user!(user_id)

        case Auth.remove_auth_methods(user) do
          {:ok, _} ->
            conn
            |> delete_session(:idp_transfer)
            |> SignInHandoff.sign_in(:mock, user, false, &Account.UserAuth.log_in_user/3)

          {:error, _step, _reason, _changes} ->
            conn |> send_resp(422, "Transfer failed") |> halt()
        end

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  @providers %{
    "apple" => {Auth.Apple, :apple},
    "centerdata" => {Auth.Centerdata, :centerdata},
    "google" => {Auth.Google, :google},
    "surfconext" => {Auth.Surfconext, :surfconext}
  }

  def confirm(conn, %{"idp" => idp}) do
    case @providers[idp] do
      {provider, satellite_key} -> confirm_transfer(conn, idp, provider, satellite_key)
      nil -> conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp confirm_transfer(conn, idp, provider, satellite_key) do
    case get_session(conn, :idp_transfer) do
      %{"idp" => ^idp, "user_id" => user_id, "userinfo" => userinfo} ->
        user = Account.Public.get_user!(user_id)

        case Auth.transfer(provider, satellite_key, user, userinfo) do
          {:ok, %{selected_identity: _}} ->
            conn
            |> delete_session(:idp_transfer)
            |> SignInHandoff.sign_in(satellite_key, user, false, &Account.UserAuth.log_in_user/3)

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
        |> SignInHandoff.end_sign_in(
          provider(idp),
          :cancelled,
          &redirect(&1, to: ~p"/user/auth/identify")
        )

      _ ->
        conn |> send_resp(404, "Not found") |> halt()
    end
  end

  defp provider("mock"), do: :mock

  defp provider(idp) do
    {_provider, satellite_key} = Map.fetch!(@providers, idp)
    satellite_key
  end
end
