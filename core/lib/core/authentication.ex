defmodule Core.Authentication do
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

    case Repo.one(Authentication.Entity, identifier: identifier) do
      nil ->
        case insert_entity(identifier) do
          {:ok, entity} -> {:ok, entity}
          error -> error
        end

      entity ->
        {:ok, entity}
    end
  end

  def obtain_actor!(type, name) do
    case obtain_actor(type, name) do
      {:ok, actor} -> actor
      error -> raise "Unable to obtain actor: #{inspect(error)}"
    end
  end

  def obtain_actor(type, name) do
    case Repo.one(Authentication.Actor, type: type, name: name) do
      nil ->
        case insert_actor(type, name) do
          {:ok, actor} -> {:ok, actor}
          error -> error
        end

      actor ->
        {:ok, actor}
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
