defmodule Frameworks.Utility.EctoHelper do
  import Ecto.Query, only: [from: 2]
  alias Ecto.{Multi, Changeset}
  alias Core.Repo

  def upsert(%{data: %{id: id}} = changeset) when not is_nil(id) do
    Repo.update(changeset)
  end

  def upsert(changeset) do
    Repo.insert(changeset)
  end

  def delete(multi, name, %table{id: id}) do
    delete(multi, name, table, id)
  end

  def delete(multi, name, table, id) do
    query = from(t in table, where: t.id == ^id)
    Multi.delete_all(multi, name, query)
  end

  def apply_virtual_change(changeset, field, virtual, delimiters)
      when is_atom(field) and is_atom(virtual) and is_list(delimiters) do
    if virtual_string = Changeset.get_change(changeset, virtual) do
      value = virtual_string |> String.split(delimiters, trim: true)
      Changeset.put_change(changeset, field, value)
    else
      changeset
    end
  end

  def prepare_virtual_icon(%{icon: {_icon_type, icon_value}} = schema) do
    %{schema | virtual_icon: icon_value}
  end

  def prepare_virtual_icon(schema) do
    %{schema | virtual_icon: Enum.random(["🟠", "🟡", "🟢", "🔵", "🟣", "🟤"])}
  end

  def apply_virtual_icon_change(changeset, icon_type) do
    if icon_value = Changeset.get_change(changeset, :virtual_icon) do
      changeset |> Changeset.put_change(:icon, {icon_type, icon_value})
    else
      changeset
    end
  end
end
