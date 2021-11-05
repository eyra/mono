defmodule Systems.Assignment.Context do
  @moduledoc """
  The assignment context.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.{
    Assignment,
    Crew
  }


  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_crew!(crew) do
    from(a in Assignment.Model, where: a.crew_id == ^crew.id)
    |> Repo.all()
  end

  def get_by_assignable(assignable, preload \\ [])
  def get_by_assignable(%Core.Survey.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_survey_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def get_by_assignable(%Core.DataDonation.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_data_donation_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def get_by_assignable(%Core.Lab.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_lab_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def create(%{} = attrs, crew, tool, auth_node) do

    assignable_field = assignable_field(tool)

    %Assignment.Model{}
    |> Assignment.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(assignable_field, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  defp assignable_field(%Core.Survey.Tool{}), do: :assignable_survey_tool
  defp assignable_field(%Core.Lab.Tool{}), do: :assignable_lab_tool
  defp assignable_field(%Core.DataDonation.Tool{}), do: :assignable_data_donation_tool

  # Crew
  def get_crew(assignment) do
    from(
      c in Crew.Model,
      where: c.id == ^assignment.id
    )
    |> Repo.one()
  end

end
