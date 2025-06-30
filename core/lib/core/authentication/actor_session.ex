defmodule Core.Authentication.ActorSession do
  @moduledoc """
  Actor authentication functions for API and session-based access.

  Provides functions for creating and verifying actor tokens,
  as well as authentication plugs for Phoenix controllers.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Core.Authentication.{Actor, ActorToken}
  alias Core.Repo

  @doc """
  Creates an API token for an actor.

  ## Examples

      iex> create_api_token(actor, "MCP Server Access")
      {:ok, "abc123def456", actor_token}
      
      iex> create_api_token(invalid_actor, "Test")
      {:error, changeset}
  """
  def create_api_token(%Actor{} = actor, name, created_by_actor \\ nil) do
    case validate_token_name(name) do
      :ok ->
        {encoded_token, changeset} = ActorToken.create_api_token(actor, name, created_by_actor)

        case Repo.insert(changeset) do
          {:ok, token} -> {:ok, encoded_token, token}
          {:error, changeset} -> {:error, changeset}
        end

      {:error, reason} ->
        changeset =
          %ActorToken{}
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.add_error(:name, reason)

        {:error, changeset}
    end
  end

  @doc """
  Creates a session token for an actor.
  """
  def create_session_token(%Actor{} = actor, created_by_actor \\ nil) do
    {encoded_token, changeset} = ActorToken.create_session_token(actor, created_by_actor)

    case Repo.insert(changeset) do
      {:ok, token} -> {:ok, encoded_token, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Verifies an API token and returns the actor.
  """
  def verify_api_token(token) when is_binary(token) do
    ActorToken.verify_api_token(token)
  end

  def verify_api_token(nil), do: {:error, :invalid_token}
  def verify_api_token(_), do: {:error, :invalid_token}

  @doc """
  Verifies a session token and returns the actor.
  """
  def verify_session_token(token) when is_binary(token) do
    ActorToken.verify_session_token(token)
  end

  def verify_session_token(nil), do: {:error, :invalid_token}
  def verify_session_token(_), do: {:error, :invalid_token}

  @doc """
  Revokes an API token.
  """
  def revoke_api_token(token) when is_binary(token) do
    ActorToken.revoke_token(token, "api")
  end

  @doc """
  Revokes a session token.
  """
  def revoke_session_token(token) when is_binary(token) do
    ActorToken.revoke_token(token, "session")
  end

  @doc """
  Revokes all API tokens for an actor.
  """
  def revoke_all_api_tokens(%Actor{} = actor) do
    ActorToken.revoke_all_actor_tokens(actor, "api")
  end

  @doc """
  Revokes all session tokens for an actor.
  """
  def revoke_all_session_tokens(%Actor{} = actor) do
    ActorToken.revoke_all_actor_tokens(actor, "session")
  end

  @doc """
  Lists all active API tokens for an actor.
  """
  def list_api_tokens(%Actor{} = actor) do
    ActorToken.list_actor_tokens(actor, "api")
  end

  @doc """
  Lists all active session tokens for an actor.
  """
  def list_session_tokens(%Actor{} = actor) do
    ActorToken.list_actor_tokens(actor, "session")
  end

  @doc """
  Plug for authenticating actors via API tokens.

  Expects the token to be provided in the Authorization header:
  `Authorization: Bearer <token>`

  On successful authentication, assigns the actor to conn.assigns.current_actor.
  On failure, sends 401 response and halts the connection.
  """
  def authenticate_api_token(conn, _opts) do
    case get_bearer_token(conn) do
      {:ok, token} ->
        case verify_api_token(token) do
          {:ok, actor} ->
            assign(conn, :current_actor, actor)

          {:error, _} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid or expired token"})
            |> halt()
        end

      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Missing or invalid Authorization header"})
        |> halt()
    end
  end

  @doc """
  Plug for optionally authenticating actors via API tokens.

  Similar to authenticate_api_token/2 but doesn't halt on missing/invalid tokens.
  Instead, assigns nil to current_actor if authentication fails.
  """
  def maybe_authenticate_api_token(conn, _opts) do
    case get_bearer_token(conn) do
      {:ok, token} ->
        case verify_api_token(token) do
          {:ok, actor} -> assign(conn, :current_actor, actor)
          {:error, _} -> assign(conn, :current_actor, nil)
        end

      {:error, _} ->
        assign(conn, :current_actor, nil)
    end
  end

  @doc """
  Plug for authenticating actors via session tokens.

  Looks for session token in cookies or Authorization header.
  """
  def authenticate_session_token(conn, _opts) do
    conn = fetch_cookies(conn)
    token = get_session_token(conn) || get_bearer_token_value(conn)

    case token do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()

      token ->
        case verify_session_token(token) do
          {:ok, actor} ->
            assign(conn, :current_actor, actor)

          {:error, _} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid or expired session"})
            |> halt()
        end
    end
  end

  @doc """
  Ensures the current actor has been authenticated.

  Should be used after an authentication plug.
  """
  def require_authenticated_actor(conn, _opts) do
    case conn.assigns[:current_actor] do
      %Actor{} ->
        conn

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Authentication required"})
        |> halt()
    end
  end

  # Private functions

  defp get_bearer_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, token}
      _ -> {:error, :no_token}
    end
  end

  defp get_bearer_token_value(conn) do
    case get_bearer_token(conn) do
      {:ok, token} -> token
      {:error, _} -> nil
    end
  end

  defp get_session_token(conn) do
    # Look for session token in cookies
    # This can be expanded based on your session management needs
    conn.cookies["actor_session_token"]
  end

  # Input validation functions

  defp validate_token_name(name) when is_binary(name) do
    cond do
      String.length(name) == 0 ->
        {:error, "cannot be blank"}

      String.length(name) > 255 ->
        {:error, "is too long (maximum is 255 characters)"}

      true ->
        :ok
    end
  end

  defp validate_token_name(nil), do: {:error, "cannot be blank"}
  defp validate_token_name(_), do: {:error, "must be a string"}
end
