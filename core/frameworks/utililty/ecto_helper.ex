defmodule Frameworks.Utility.EctoHelper do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  def delete(multi, name, %table{id: id}) do
    delete(multi, name, table, id)
  end

  def delete(multi, name, table, id) do
    query = from(t in table, where: t.id == ^id)
    Multi.delete_all(multi, name, query)
  end
end
