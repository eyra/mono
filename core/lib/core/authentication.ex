defmodule Core.Authentication do
  import Core.Authentication.Queries
  alias Ecto.Multi
  alias Core.Repo
  alias Core.Authentication

  def obtain_entity!(subject) do
    case obtain_entity(subject) do
      {:ok, entity} -> entity
      error -> raise "Unable to obtain entity: #{inspect(error)}"
    end
  end

  def obtain_entity(%module{id: id} = _subject) do
    identifier = encode_identifier(module, id)

    result = 
      Multi.new()
      |> Multi.run(:entity, fn _, _ ->
        case Repo.one(entity_query(identifier)) do
          nil ->
            insert_entity(identifier)
          entity ->
            {:ok, entity}
        end
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{entity: entity}} ->
        {:ok, entity}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def obtain_actor!(type, name) do
    case obtain_actor(type, name) do
      {:ok, actor} -> actor
      error -> raise "Unable to obtain actor: #{inspect(error)}"
    end
  end

  def obtain_actor(type, name) when is_atom(type) and is_binary(name) do
    result = 
      Multi.new()
      |> Multi.run(:actor, fn _, _ ->
        case Repo.one(actor_query(type, name)) do
          nil ->
            insert_actor(type, name)
          actor ->
            {:ok, actor}
          end
        end)
        |> Repo.transaction()


    case result do
      {:ok, %{actor: actor}} ->
        {:ok, actor}
      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def fetch_subject(%Authentication.Entity{identifier: identifier}) do
    {module, id} = decode_identifier(identifier)

    module
    |> String.to_existing_atom()
    |> Repo.get!(id)
  end

  defp insert_entity(identifier) do
    %Authentication.Entity{}
    |> Authentication.Entity.change(%{identifier: identifier})
    |> Authentication.Entity.validate()
    |> Core.Repo.insert()
  end

  defp insert_actor(type, name) do
    %Authentication.Actor{}
    |> Authentication.Actor.change(%{type: type, name: name})
    |> Authentication.Actor.validate()
    |> Core.Repo.insert()
  end

  defp encode_identifier(module, id) do
    "#{module}:#{id}"
  end

  defp decode_identifier(identifier) do
    [module, id] = String.split(identifier, ":")
    {module, id}
  end
end
