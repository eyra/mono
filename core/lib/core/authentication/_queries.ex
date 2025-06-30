defmodule Core.Authentication.Queries do
  import Ecto.Query
  import Frameworks.Utility.Query, only: [build: 3]
  alias Core.Authentication

  def actor_query() do
    from(a in Authentication.Actor, as: :actor)
  end

  def actor_query(type, name) do
    build(actor_query(), :actor, [type == ^type, name == ^name])
  end

  def entity_query() do
    from(e in Authentication.Entity, as: :entity)
  end

  def entity_query(identifier) do
    build(entity_query(), :entity, [identifier == ^identifier])
  end
end
