defmodule Core.Authentication.ActorToken do
  @moduledoc """
  Token-based authentication for Actors.

  Provides API tokens and session tokens for Actor authentication.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import Ecto.Query
  alias Core.Repo

  alias Core.Authentication.Actor

  @hash_algorithm :sha256
  @rand_size 32

  # Token contexts
  @api_context "api"
  @session_context "session"

  schema "actor_tokens" do
    field(:token, :binary)
    field(:context, :string)
    field(:name, :string)
    field(:expires_at, :naive_datetime)
    field(:last_used_at, :naive_datetime)

    belongs_to(:actor, Actor)
    belongs_to(:created_by_actor, Actor, foreign_key: :created_by_actor_id)

    timestamps()
  end

  @doc """
  Generates a token for the given actor and context.

  ## Examples

      iex> generate_actor_token(actor, "api", "MCP Server Access")
      {encoded_token, actor_token}
      
      iex> generate_actor_token(actor, "session")
      {encoded_token, actor_token}
  """
  def generate_actor_token(actor, context, name \\ nil, created_by_actor \\ nil) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    attrs = %{
      token: hashed_token,
      context: context,
      name: name || "#{context}_token",
      actor_id: actor.id,
      created_by_actor_id: created_by_actor && created_by_actor.id
    }

    attrs =
      case context do
        @api_context ->
          # API tokens don't expire by default
          attrs

        @session_context ->
          # Session tokens expire in 30 days
          Map.put(
            attrs,
            :expires_at,
            DateTime.utc_now()
            |> DateTime.add(30, :day)
            |> DateTime.to_naive()
            |> NaiveDateTime.truncate(:second)
          )

        _ ->
          attrs
      end

    changeset =
      %__MODULE__{}
      |> cast(attrs, [:token, :context, :name, :actor_id, :expires_at, :created_by_actor_id])
      |> validate_required([:token, :context, :name, :actor_id])
      |> validate_inclusion(:context, [@api_context, @session_context])
      |> unique_constraint(:token)

    {Base.url_encode64(token, padding: false), changeset}
  end

  @doc """
  Creates an API token for an actor.
  """
  def create_api_token(actor, name, created_by_actor \\ nil) do
    generate_actor_token(actor, @api_context, name, created_by_actor)
  end

  @doc """
  Creates a session token for an actor.
  """
  def create_session_token(actor, created_by_actor \\ nil) do
    generate_actor_token(actor, @session_context, "session", created_by_actor)
  end

  @doc """
  Verifies a token and returns the associated actor.

  Updates last_used_at timestamp if token is valid.
  """
  def verify_token(encoded_token, context) when is_binary(encoded_token) and is_binary(context) do
    with {:ok, token} <- Base.url_decode64(encoded_token, padding: false),
         hashed_token <- :crypto.hash(@hash_algorithm, token),
         %__MODULE__{} = actor_token <- get_valid_token(hashed_token, context) do
      # Update last used timestamp
      update_last_used(actor_token)

      {:ok, actor_token.actor}
    else
      _ -> {:error, :invalid_token}
    end
  end

  def verify_token(nil, _context), do: {:error, :invalid_token}
  def verify_token(_token, nil), do: {:error, :invalid_token}
  def verify_token(_token, _context), do: {:error, :invalid_token}

  @doc """
  Verifies an API token.
  """
  def verify_api_token(encoded_token) do
    verify_token(encoded_token, @api_context)
  end

  @doc """
  Verifies a session token.
  """
  def verify_session_token(encoded_token) do
    verify_token(encoded_token, @session_context)
  end

  @doc """
  Revokes a token by deleting it.
  """
  def revoke_token(encoded_token, context) when is_binary(encoded_token) and is_binary(context) do
    with {:ok, token} <- Base.url_decode64(encoded_token, padding: false),
         hashed_token <- :crypto.hash(@hash_algorithm, token),
         %__MODULE__{} = actor_token <- get_token_by_hash(hashed_token, context) do
      Repo.delete(actor_token)
    else
      _ -> {:error, :token_not_found}
    end
  end

  def revoke_token(nil, _context), do: {:error, :token_not_found}
  def revoke_token(_token, nil), do: {:error, :token_not_found}
  def revoke_token(_token, _context), do: {:error, :token_not_found}

  @doc """
  Revokes all tokens for an actor in a given context.
  """
  def revoke_all_actor_tokens(actor, context) do
    from(t in __MODULE__,
      where: t.actor_id == ^actor.id and t.context == ^context
    )
    |> Repo.delete_all()
  end

  @doc """
  Lists all active tokens for an actor.
  """
  def list_actor_tokens(actor, context \\ nil) do
    query = from(t in __MODULE__, where: t.actor_id == ^actor.id)

    query =
      if context do
        from(t in query, where: t.context == ^context)
      else
        query
      end

    from(t in query, where: is_nil(t.expires_at) or t.expires_at > ^NaiveDateTime.utc_now())
    |> Repo.all()
  end

  @doc """
  Cleans up expired tokens.
  """
  def cleanup_expired_tokens do
    from(t in __MODULE__,
      where: not is_nil(t.expires_at) and t.expires_at <= ^NaiveDateTime.utc_now()
    )
    |> Repo.delete_all()
  end

  # Private functions

  defp get_valid_token(hashed_token, context) do
    from(t in __MODULE__,
      where: t.token == ^hashed_token and t.context == ^context,
      where: is_nil(t.expires_at) or t.expires_at > ^NaiveDateTime.utc_now(),
      preload: [:actor]
    )
    |> Repo.one()
    |> case do
      %__MODULE__{actor: %Actor{active: true}} = token -> token
      _ -> nil
    end
  end

  defp get_token_by_hash(hashed_token, context) do
    from(t in __MODULE__,
      where: t.token == ^hashed_token and t.context == ^context
    )
    |> Repo.one()
  end

  defp update_last_used(actor_token) do
    actor_token
    |> cast(%{last_used_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)}, [
      :last_used_at
    ])
    |> Repo.update()
  end

  # Required by Frameworks.Utility.Schema behavior
  def preload_graph(:down), do: [:actor]
  def preload_graph(_), do: []
end
