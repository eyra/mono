defmodule Systems.Account.FeaturesModel do
  @moduledoc """
  This schema contains features of members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Systems.Account.User

  alias Core.Enums.Genders
  require Core.Enums.Genders

  alias Systems.{
    Student
  }

  schema "user_features" do
    field(:gender, Ecto.Enum, values: Genders.schema_values())
    field(:birth_year, :integer)
    field(:study_program_codes, {:array, Ecto.Atom})

    belongs_to(:user, User)
    timestamps()
  end

  @fields ~w(gender birth_year study_program_codes)a
  @required_fields ~w()a

  @doc false
  def changeset(tool, :mount, params) do
    tool
    |> cast(params, @fields)
  end

  def changeset(tool, :auto_save, params) do
    current_year = Date.utc_today().year
    min_year = current_year - 130
    max_year = current_year - 8

    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_birth_year(min_year, max_year)
  end

  defp validate_birth_year(changeset, min_year, max_year) do
    changeset
    |> validate_number(:birth_year,
      greater_than_or_equal_to: min_year,
      less_than_or_equal_to: max_year,
      message: "must be between #{min_year} and #{max_year}"
    )
  end

  def get_student_classes(%{study_program_codes: [_ | _] = codes}) do
    Enum.map(codes, &Student.Codes.text(&1))
  end

  def get_student_classes(_), do: []
end
