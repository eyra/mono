defmodule Systems.Pool.CriteriaModel do
  @moduledoc """
  This schema contains features of members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Pool.SubmissionModel

  alias Core.Enums.{Genders, DominantHands, NativeLanguages}
  require Core.Enums.{Genders, DominantHands, NativeLanguages}

  schema "eligibility_criteria" do
    field(:genders, {:array, Ecto.Enum}, values: Genders.schema_values())
    field(:dominant_hands, {:array, Ecto.Enum}, values: DominantHands.schema_values())
    field(:native_languages, {:array, Ecto.Enum}, values: NativeLanguages.schema_values())
    field(:study_program_codes, {:array, Ecto.Atom})

    belongs_to(:submission, SubmissionModel)

    timestamps()
  end

  @fields ~w(genders dominant_hands native_languages study_program_codes)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
  end

  def eligitable?(nil, nil), do: true

  def eligitable?(criteria, nil) do
    meets?(criteria.genders, nil) &&
      meets?(criteria.dominant_hands, nil) &&
      meets?(criteria.native_languages, nil) &&
      meets?(criteria.study_program_codes, nil)
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
