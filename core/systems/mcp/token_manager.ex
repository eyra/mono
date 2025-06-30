defmodule Systems.MCP.TokenManager do
  @moduledoc """
  Management functions for Actor tokens specifically for MCP server access.

  Provides higher-level functions for creating, managing, and monitoring
  MCP-specific API tokens.
  """

  alias Core.Authentication.{Actor, ActorSession, ActorToken}
  alias Core.Repo
  import Ecto.Query

  @doc """
  Creates an MCP API token for an actor with appropriate naming.
  """
  def create_mcp_token(%Actor{} = actor, token_name \\ nil, created_by_actor \\ nil) do
    name = token_name || "MCP Server Access - #{DateTime.utc_now() |> DateTime.to_date()}"

    case validate_token_name(name) do
      :ok -> ActorSession.create_api_token(actor, name, created_by_actor)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Creates an actor specifically for MCP access.
  """
  def create_mcp_actor(name, description \\ nil, type \\ :agent) do
    actor_attrs = %{
      name: name,
      description: description || "MCP Server Access Actor",
      type: type,
      active: true
    }

    changeset =
      %Actor{}
      |> Actor.change(actor_attrs)
      |> Actor.validate()
      |> validate_actor_constraints(name, description)

    case changeset.valid? do
      true -> Repo.insert(changeset)
      false -> {:error, changeset}
    end
  end

  @doc """
  Creates an actor and generates an MCP token in one operation.
  """
  def create_mcp_actor_with_token(name, description \\ nil, token_name \\ nil, type \\ :agent) do
    case create_mcp_actor(name, description, type) do
      {:ok, actor} ->
        case create_mcp_token(actor, token_name) do
          {:ok, token, token_record} ->
            {:ok,
             %{
               actor: actor,
               token: token,
               token_record: token_record,
               instructions: %{
                 token: token,
                 usage: "Use this token in the Authorization header: 'Bearer #{token}'"
               }
             }}

          {:error, changeset} ->
            # Clean up the actor if token creation fails
            Repo.delete(actor)
            {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Lists all MCP-related tokens with usage statistics.
  """
  def list_mcp_tokens do
    from(t in ActorToken,
      where: t.context == "api",
      preload: [:actor],
      order_by: [desc: t.inserted_at, desc: t.id]
    )
    |> Repo.all()
    |> Enum.map(&format_token_info/1)
  end

  @doc """
  Gets token usage statistics for monitoring.
  """
  def get_token_usage_stats do
    active_tokens =
      from(t in ActorToken,
        where: t.context == "api",
        where: is_nil(t.expires_at) or t.expires_at > ^NaiveDateTime.utc_now(),
        select: count(t.id)
      )
      |> Repo.one()

    recently_used =
      from(t in ActorToken,
        where: t.context == "api",
        where: not is_nil(t.last_used_at),
        where: t.last_used_at > ^NaiveDateTime.add(NaiveDateTime.utc_now(), -7, :day),
        select: count(t.id)
      )
      |> Repo.one()

    %{
      total_active_tokens: active_tokens,
      recently_used_tokens: recently_used,
      last_updated: NaiveDateTime.utc_now()
    }
  end

  @doc """
  Deactivates an actor and revokes all their tokens.
  """
  def deactivate_actor(%Actor{} = actor) do
    Repo.transaction(fn ->
      # Deactivate the actor
      updated_actor =
        actor
        |> Actor.change(%{active: false})
        |> Repo.update!()

      # Revoke all tokens
      api_revocation = ActorSession.revoke_all_api_tokens(actor)
      session_revocation = ActorSession.revoke_all_session_tokens(actor)

      {updated_actor, %{api_tokens: api_revocation, session_tokens: session_revocation}}
    end)
  end

  @doc """
  Rotates an API token by creating a new one and optionally revoking the old one.
  """
  def rotate_token(old_token, new_token_name \\ nil, revoke_old \\ true) do
    # Validate new token name if provided
    case validate_token_name_if_provided(new_token_name) do
      :ok ->
        case ActorSession.verify_api_token(old_token) do
          {:ok, actor} ->
            create_and_handle_rotation(actor, new_token_name, old_token, revoke_old)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Cleans up expired tokens and returns count of cleaned tokens.
  """
  def cleanup_expired_tokens do
    {count, _} = ActorToken.cleanup_expired_tokens()
    {:ok, count}
  end

  # Private functions

  defp create_and_handle_rotation(actor, new_token_name, old_token, revoke_old) do
    case create_mcp_token(actor, new_token_name) do
      {:ok, new_token, token_record} ->
        result = %{
          new_token: new_token,
          token_record: token_record,
          actor: actor
        }

        handle_token_rotation(result, old_token, revoke_old)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp handle_token_rotation(result, old_token, true) do
    ActorSession.revoke_api_token(old_token)
    {:ok, Map.put(result, :old_token_revoked, true)}
  end

  defp handle_token_rotation(result, _old_token, false) do
    {:ok, Map.put(result, :old_token_revoked, false)}
  end

  defp format_token_info(token) do
    %{
      id: token.id,
      name: token.name,
      actor_name: token.actor.name,
      actor_type: token.actor.type,
      actor_active: token.actor.active,
      created_at: token.inserted_at,
      last_used_at: token.last_used_at,
      expires_at: token.expires_at,
      is_expired:
        if(token.expires_at,
          do: NaiveDateTime.compare(token.expires_at, NaiveDateTime.utc_now()) == :lt,
          else: false
        )
    }
  end

  # Validation functions

  defp validate_token_name(name) when is_binary(name) do
    cond do
      String.length(name) > 255 ->
        {:error, "Token name too long (maximum 255 characters)"}

      String.length(name) < 1 ->
        {:error, "Token name cannot be empty"}

      true ->
        :ok
    end
  end

  defp validate_token_name(_), do: {:error, "Token name must be a string"}

  defp validate_actor_name(name) when is_binary(name) do
    cond do
      String.length(name) > 255 ->
        {:error, "Actor name too long (maximum 255 characters)"}

      String.length(name) < 1 ->
        {:error, "Actor name cannot be empty"}

      true ->
        :ok
    end
  end

  defp validate_actor_name(_), do: {:error, "Actor name must be a string"}

  defp validate_actor_description(nil), do: :ok

  defp validate_actor_description(description) when is_binary(description) do
    if String.length(description) > 1000 do
      {:error, "Actor description too long (maximum 1000 characters)"}
    else
      :ok
    end
  end

  defp validate_actor_description(_), do: {:error, "Actor description must be a string"}

  defp validate_token_name_if_provided(nil), do: :ok
  defp validate_token_name_if_provided(name), do: validate_token_name(name)

  defp validate_actor_constraints(changeset, name, description) do
    import Ecto.Changeset

    changeset =
      case validate_actor_name(name) do
        :ok -> changeset
        {:error, message} -> add_error(changeset, :name, message)
      end

    case validate_actor_description(description) do
      :ok -> changeset
      {:error, message} -> add_error(changeset, :description, message)
    end
  end
end
