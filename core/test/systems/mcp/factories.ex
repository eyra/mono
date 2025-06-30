defmodule Systems.MCP.Factories do
  @moduledoc """
  Factory functions for creating test data for MCP system.
  """

  alias Core.Authentication.{Actor, ActorToken, ActorSession}
  alias Core.Repo

  def build_actor(attrs \\ %{}) do
    unique_suffix = System.unique_integer([:positive])

    %Actor{
      type: :agent,
      name: "Test MCP Agent #{unique_suffix}",
      description: "Test agent for MCP operations",
      active: true
    }
    |> struct!(attrs)
  end

  def create_actor(attrs \\ %{}) do
    build_actor(attrs)
    |> Repo.insert!()
  end

  def build_system_actor(attrs \\ %{}) do
    build_actor(Map.merge(%{type: :system, name: "Test System Actor"}, attrs))
  end

  def create_system_actor(attrs \\ %{}) do
    build_system_actor(attrs)
    |> Repo.insert!()
  end

  def build_inactive_actor(attrs \\ %{}) do
    build_actor(Map.merge(%{active: false, name: "Inactive Actor"}, attrs))
  end

  def create_inactive_actor(attrs \\ %{}) do
    build_inactive_actor(attrs)
    |> Repo.insert!()
  end

  def create_actor_with_token(actor_attrs \\ %{}, token_name \\ "Test Token") do
    actor = create_actor(actor_attrs)
    {:ok, token, token_record} = ActorSession.create_api_token(actor, token_name)
    {actor, token, token_record}
  end

  def create_system_actor_with_token(actor_attrs \\ %{}, token_name \\ "System Token") do
    actor = create_system_actor(actor_attrs)
    {:ok, token, token_record} = ActorSession.create_api_token(actor, token_name)
    {actor, token, token_record}
  end

  def create_expired_token_actor do
    unique_suffix = System.unique_integer([:positive])
    actor = create_actor(%{name: "Expired Actor #{unique_suffix}"})

    expired_date =
      NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :day) |> NaiveDateTime.truncate(:second)

    # Create an expired token using proper token generation
    {encoded_token, changeset} = ActorToken.generate_actor_token(actor, "api", "Expired Token")

    # Modify the changeset to set expiration in the past
    changeset = Ecto.Changeset.put_change(changeset, :expires_at, expired_date)
    token_record = Repo.insert!(changeset)

    {actor, encoded_token, token_record}
  end
end
