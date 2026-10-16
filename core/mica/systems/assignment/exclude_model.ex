defmodule Systems.Assignment.ExcludeModel do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Ecto.Multi

  alias Systems.{
    Assignment
  }

  @primary_key false
  schema "assignment_excludes" do
    field(:from_id, :id)
    field(:to_id, :id)
    timestamps()
  end

  @fields ~w()a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
  end

  def exclude(multi, %Assignment.Model{id: from_id}, %Assignment.Model{id: to_id}) do
    exclude(multi, from_id, to_id)
  end

  def exclude(multi, from_id, to_id) do
    Multi.insert(
      multi,
      "exclude_#{from_id}_#{to_id}",
      %Assignment.ExcludeModel{from_id: from_id, to_id: to_id},
      on_conflict: :nothing
    )
  end

  def include(multi, %Assignment.Model{id: from_id}, %Assignment.Model{id: to_id}) do
    include(multi, from_id, to_id)
  end

  def include(multi, from_id, to_id) do
    Multi.delete_all(
      multi,
      "include_#{from_id}_#{to_id}",
      from(ex in Assignment.ExcludeModel, where: ex.from_id == ^from_id and ex.to_id == ^to_id)
    )
  end
end
