defmodule Core.Accounts.Features do
  @moduledoc """
  This schema contains features of members.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Accounts.User

  alias Core.Enums.{Genders, DominantHands, NativeLanguages, StudyPrograms, StudyYears}
  require Core.Enums.{Genders, DominantHands, NativeLanguages, StudyPrograms, StudyYears}

  schema "user_features" do
    field(:gender, Ecto.Enum, values: Genders.schema_values())
    field(:dominant_hand, Ecto.Enum, values: DominantHands.schema_values())
    field(:native_language, Ecto.Enum, values: NativeLanguages.schema_values())
    field(:study_programs, {:array, Ecto.Enum}, values: StudyPrograms.schema_values())
    field(:study_years, {:array, Ecto.Enum}, values: StudyYears.schema_values())

    belongs_to(:user, User)
    timestamps()
  end

  @fields ~w(gender dominant_hand native_language study_programs study_years)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
  end
end
