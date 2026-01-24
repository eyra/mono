defmodule Frameworks.UserState.Schemas.V1 do
  @moduledoc """
  Legacy UserState schema (version 1).

  This schema represents the old format where leaf values could be
  stored at intermediate paths. For example:

  - `assignment/<id>` → integer (was storing crew_id directly)

  This caused conflicts when V2 tried to store:
  - `assignment/<id>/crew/<id>/task` → integer

  The parser would fail with BadMapError when trying to traverse
  through an integer value.

  ## Migration

  V1 data is migrated to V2 by:
  - Dropping orphan leaf values at intermediate paths
  - Logging what was dropped for audit purposes
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
      field :id, :integer
      field :task, :integer
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

    alias Frameworks.UserState.Schemas.V1.Crew

    @primary_key false
    embedded_schema do
      field :id, :integer
      # Legacy: stored value directly (e.g., crew_id)
      field :value, :integer
      # V1 also supported nested crews (partial V2 compatibility)
      embeds_many :crews, Crew, on_replace: :delete
    end

    def changeset(struct, attrs) do
      struct
      |> cast(attrs, [:id, :value])
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
      field :id, :integer
      field :chapter, :integer
      field :page, :integer
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
  alias __MODULE__.Manual

  @version 1

  def version, do: @version

  @primary_key false
  embedded_schema do
    embeds_many :assignments, Assignment, on_replace: :delete
    embeds_many :manuals, Manual, on_replace: :delete
  end

  @doc """
  Validates user state attributes against the V1 schema.

  V1 is more permissive - it allows leaf values at intermediate paths.
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
  Converts V1 state to nested map format.

  Note: V1 states should be migrated to V2 before use. This function
  exists mainly for consistency with V2.
  """
  def to_nested_map(%__MODULE__{} = _state) do
    # V1 states should be migrated to V2, not converted directly
    # Return empty map since V1 format is not compatible with current app
    %{}
  end
end
