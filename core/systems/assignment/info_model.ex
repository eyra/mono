defmodule Systems.Assignment.InfoModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Frameworks.Utility.Model

  require Core.Enums.Devices
  import Ecto.Changeset

  alias Systems.{
    Assignment
  }

  schema "assignment_info" do
    field(:title, :string)
    field(:subtitle, :string)
    field(:image_id, :string)
    field(:logo_url, :string)

    field(:subject_count, :integer)
    field(:duration, :string)
    field(:language, :string)
    field(:devices, {:array, Ecto.Enum}, values: Core.Enums.Devices.schema_values())
    field(:ethical_approval, :boolean)
    field(:ethical_code, :string)

    has_one(:assignment, Assignment.Model, foreign_key: :id)

    timestamps()
  end

  @operational_fields ~w(title subtitle subject_count duration ethical_code ethical_approval devices)a
  @fields @operational_fields ++ ~w(image_id logo_url language)a

  @required_fields ~w()a

  @impl true
  def operational_fields, do: @operational_fields

  @impl true
  def operational_validation(changeset) do
    validate_true(changeset, :ethical_approval)
  end

  defp validate_true(changeset, field) do
    case get_field(changeset, field) do
      true -> changeset
      _ -> add_error(changeset, field, "is not true")
    end
  end

  def changeset(info, :auto_save, params) do
    info
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def changeset(info, _, params) do
    info
    |> cast(params, @fields)
  end

  def languages(%{language: language}) when not is_nil(language), do: [language]
  def languages(_), do: []

  def devices(%{devices: devices}) when not is_nil(devices), do: devices
  def devices(_), do: []

  def spot_count(%{subject_count: subject_count}) when not is_nil(subject_count),
    do: subject_count

  def spot_count(_), do: 0

  def duration(%{duration: duration}) when not is_nil(duration) do
    case Integer.parse(duration) do
      :error -> 0
      {duration, _} -> duration
    end
  end

  def duration(_), do: 0
end
