defmodule Frameworks.Utility.EctoHelper do
  import Ecto.Query, only: [from: 2]
  alias Ecto.{Multi, Changeset}
  alias Core.Repo
  alias Frameworks.Signal

  def upsert(%{data: %{id: id}} = changeset) when not is_nil(id) do
    Repo.update(changeset)
  end

  def upsert(changeset) do
    Repo.insert(changeset)
  end

  def update_and_dispatch(changeset, key) do
    Multi.new()
    |> Repo.multi_update(key, changeset)
    |> Signal.Public.multi_dispatch({key, :update_and_dispatch}, %{changeset: changeset})
    |> Repo.transaction()
  end

  def delete(multi, name, %table{id: id}) do
    delete(multi, name, table, id)
  end

  def delete(multi, name, table, objects) when is_list(objects) do
    ids = Enum.map(objects, & &1.id)
    delete_all(multi, name, table, ids)
  end

  def delete(multi, name, table, id) when is_integer(id) do
    delete_all(multi, name, table, [id])
  end

  def delete_all(multi, name, table, ids) when is_list(ids) do
    query = from(t in table, where: t.id in ^ids)
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

  # Multi

  def run(multi, name, function) do
    case :erlang.fun_info(function)[:arity] do
      1 ->
        Multi.run(multi, name, fn _, args ->
          function.(args)
        end)

      2 ->
        Multi.run(multi, name, fn _, args ->
          Multi.new()
          |> function.(args)
          |> Repo.transaction()
        end)

      _ ->
        multi
    end
  end
end
