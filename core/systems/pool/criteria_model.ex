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

    belongs_to(:submission, SubmissionModel)

    timestamps()
  end

  @fields ~w(genders)a

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, @fields)
  end

  def eligitable?(nil, nil), do: true

  def eligitable?(criteria, nil) do
    meets?(criteria.genders, nil)
  end

  def eligitable?(criteria, %{gender: gender}) do
    meets?(criteria.genders, gender)
  end

  defp meets?(field, value) when is_list(value) do
    Enum.find_value(value, &meets?(field, &1))
  end

  defp meets?(field, value) when is_atom(value) do
    field == nil || Enum.empty?(field) || Enum.member?(field, value)
  end
end
