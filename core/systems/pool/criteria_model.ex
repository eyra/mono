defmodule Systems.Pool.CriteriaModel do
  @moduledoc """
  This schema contains features of members.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Pool.SubmissionModel

  alias Core.Enums.Genders
  require Core.Enums.Genders

  schema "eligibility_criteria" do
    field(:genders, {:array, Ecto.Enum}, values: Genders.schema_values())
    field(:min_birth_year, :integer)
    field(:max_birth_year, :integer)

    belongs_to(:submission, SubmissionModel)

    timestamps()
  end

  @fields ~w(genders min_birth_year max_birth_year)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
    |> validate_min_max()
  end

  defp validate_min_max(changeset) do
    min_year = get_field(changeset, :min_birth_year)
    max_year = get_field(changeset, :max_birth_year)

    if min_year && max_year && min_year > max_year do
      add_error(changeset, :max_birth_year, "must be greater than or equal to min birth year")
    else
      changeset
    end
  end

  def eligitable?(nil, nil), do: true

  def eligitable?(criteria, nil) do
    meets?(criteria.genders, nil) and meets_birth_year?(criteria, nil)
  end

  def eligitable?(criteria, %{gender: gender, birth_year: birth_year}) do
    meets?(criteria.genders, gender) and meets_birth_year?(criteria, birth_year)
  end

  def eligitable?(criteria, %{gender: gender}) do
    meets?(criteria.genders, gender) and meets_birth_year?(criteria, nil)
  end

  defp meets_birth_year?(criteria, birth_year) do
    min_year = criteria.min_birth_year
    max_year = criteria.max_birth_year

    cond do
      min_year == nil and max_year == nil -> true
      birth_year == nil -> false
      min_year != nil and birth_year < min_year -> false
      max_year != nil and birth_year > max_year -> false
      true -> true
    end
  end

  defp meets?(field, value) when is_list(value) do
    Enum.find_value(value, &meets?(field, &1))
  end

  defp meets?(field, value) when is_atom(value) do
    field == nil || Enum.empty?(field) || Enum.member?(field, value)
  end
end

defimpl Core.Persister, for: Systems.Pool.CriteriaModel do
  alias Systems.Pool

  def save(criteria, changeset) do
    case Pool.Public.update(criteria, changeset) do
      {:ok, %{criteria: criteria}} -> {:ok, criteria}
      _ -> {:error, changeset}
    end
  end
end
