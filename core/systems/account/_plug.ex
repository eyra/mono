defmodule Systems.Account.Plug do
  @behaviour Plug

  require Logger

  import Plug.Conn
  alias Systems.Account

  @valid_participant_path ~r"^\/((assignment\/(callback\/)?\d.*)|(a\/.{6,}))$"

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case current_user(conn) do
      {:ok, %{} = user} ->
        if restricted?(user) do
          signof_restricted(conn)
        else
          assign(conn, :current_user, user)
        end

      _ ->
        conn
    end
  end

  defp restricted?(user),
    do: Account.Public.external?(user) or Account.Public.affiliate?(user)

  defp current_user(conn) do
    if user_token = get_session(conn, :user_token) do
      {:ok, Account.Public.get_user_by_session_token(user_token)}
    else
      {:error, :no_user_token}
    end
  end

  defp signof_restricted(%{request_path: request_path} = conn) do
    if Regex.match?(@valid_participant_path, request_path) do
      conn
    else
      Logger.warning(
        "#[#{__MODULE__}] Signing off restricted user, no regex match: request_path=#{request_path}, regex=#{inspect(@valid_participant_path)}"
      )

      Account.UserAuth.forget_user(conn)
    end
  end
end
