defmodule Core.Pools.Criteria do
  @moduledoc """
  This schema contains features of members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Pools.Submission

  alias Core.Enums.{Genders, DominantHands, NativeLanguages, StudyProgramCodes}
  require Core.Enums.{Genders, DominantHands, NativeLanguages, StudyProgramCodes}

  schema "eligibility_criteria" do
    field(:genders, {:array, Ecto.Enum}, values: Genders.schema_values())
    field(:dominant_hands, {:array, Ecto.Enum}, values: DominantHands.schema_values())
    field(:native_languages, {:array, Ecto.Enum}, values: NativeLanguages.schema_values())
    field(:study_program_codes, {:array, Ecto.Enum}, values: StudyProgramCodes.schema_values())

    belongs_to(:submission, Submission)

    timestamps()
  end

  @fields ~w(genders dominant_hands native_languages study_program_codes)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
  end

  def eligitable?(
        criteria,
        %{
          gender: gender,
          dominant_hand: dominant_hand,
          native_language: native_language,
          study_program_codes: study_program_codes
        }
      ) do
    meets?(criteria.genders, gender) &&
      meets?(criteria.dominant_hands, dominant_hand) &&
      meets?(criteria.native_languages, native_language) &&
      meets?(criteria.study_program_codes, study_program_codes)
  end

  defp meets?(field, value) when is_list(value) do
    Enum.find_value(value, &meets?(field, &1))
  end

  defp meets?(field, value) when is_atom(value) do
    field == nil || Enum.empty?(field) || Enum.member?(field, value)
  end
end
