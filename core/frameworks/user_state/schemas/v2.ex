defmodule Frameworks.UserState.Schemas.V2 do
  @moduledoc """
  Current UserState schema (version 2).

  Defines the valid structure for user state stored in localStorage.
  This schema is used for both validation and documentation of the
  expected data format.

  ## Structure

  Valid paths:
  - `assignment/<id>/crew/<id>/task` → integer (selected task ID)
  - `manual/<id>/chapter` → integer (selected chapter ID)
  - `manual/<id>/page` → integer (selected page ID)

  ## Usage

  This schema validates the complete user state after parsing from
  flat localStorage format into a nested structure.
  """

  use Ecto.Schema
  import Ecto.Changeset

  # Define nested modules first so they can be used in pattern matching
  defmodule Crew do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:id, :integer)
      field(:task, :integer)
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:id, :task])
      |> validate_required([:id])
      |> validate_number(:id, greater_than: 0)
    end
  end

  defmodule Assignment do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    alias Frameworks.UserState.Schemas.V2.Crew

    @primary_key false
    embedded_schema do
      field(:id, :integer)
      embeds_many(:crews, Crew, on_replace: :delete)
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:id])
      |> validate_required([:id])
      |> validate_number(:id, greater_than: 0)
      |> cast_embed(:crews, with: &Crew.changeset/2)
    end
  end

  defmodule Manual do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field(:id, :integer)
      field(:chapter, :integer)
      field(:page, :integer)
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:id, :chapter, :page])
      |> validate_required([:id])
      |> validate_number(:id, greater_than: 0)
    end
  end

  # Now define the main schema
  alias __MODULE__.Assignment
  alias __MODULE__.Crew
  alias __MODULE__.Manual

  @version 2

  def version, do: @version

  @primary_key false
  embedded_schema do
    embeds_many(:assignments, Assignment, on_replace: :delete)
    embeds_many(:manuals, Manual, on_replace: :delete)
  end

  @doc """
  Validates user state attributes against the V2 schema.

  Returns `{:ok, validated_state}` if valid, `{:error, changeset}` otherwise.
  """
  def validate(attrs) when is_map(attrs) do
    changeset = changeset(%__MODULE__{}, attrs)

    if changeset.valid? do
      {:ok, apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [])
    |> cast_embed(:assignments, with: &Assignment.changeset/2)
    |> cast_embed(:manuals, with: &Manual.changeset/2)
  end

  @doc """
  Converts validated V2 state back to nested map format.

  This is the format used internally by the application.
  """
  def to_nested_map(%__MODULE__{} = state) do
    %{}
    |> maybe_put_assignments(state.assignments)
    |> maybe_put_manuals(state.manuals)
  end

  defp maybe_put_assignments(map, []), do: map

  defp maybe_put_assignments(map, assignments) do
    assignment_map =
      assignments
      |> Enum.map(fn %Assignment{id: id, crews: crews} ->
        crew_map =
          crews
          |> Enum.map(fn %Crew{id: crew_id, task: task} ->
            {crew_id, %{task: task} |> reject_nil_values()}
          end)
          |> Enum.into(%{})

        {id, %{crew: crew_map} |> reject_nil_values()}
      end)
      |> Enum.into(%{})

    Map.put(map, :assignment, assignment_map)
  end

  defp maybe_put_manuals(map, []), do: map

  defp maybe_put_manuals(map, manuals) do
    manual_map =
      manuals
      |> Enum.map(fn %Manual{id: id, chapter: chapter, page: page} ->
        {id, %{chapter: chapter, page: page} |> reject_nil_values()}
      end)
      |> Enum.into(%{})

    Map.put(map, :manual, manual_map)
  end

  defp reject_nil_values(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end
end
