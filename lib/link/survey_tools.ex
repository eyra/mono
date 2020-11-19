defmodule Link.SurveyTools do
  @moduledoc """
  The SurveyTools context.
  """

  import Ecto.Query, warn: false
  alias Link.Repo

  alias Link.SurveyTools.SurveyTool

  @doc """
  Returns the list of survey_tools.

  ## Examples

      iex> list_survey_tools()
      [%SurveyTool{}, ...]

  """
  def list_survey_tools do
    Repo.all(SurveyTool)
  end

  @doc """
  Gets a single survey_tool.

  Raises `Ecto.NoResultsError` if the Survey tool does not exist.

  ## Examples

      iex> get_survey_tool!(123)
      %SurveyTool{}

      iex> get_survey_tool!(456)
      ** (Ecto.NoResultsError)

  """
  def get_survey_tool!(id), do: Repo.get!(SurveyTool, id)

  @doc """
  Creates a survey_tool.

  ## Examples

      iex> create_survey_tool(%{field: value})
      {:ok, %SurveyTool{}}

      iex> create_survey_tool(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_survey_tool(attrs, study) do
    %SurveyTool{}
    |> SurveyTool.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Repo.insert()
  end

  @doc """
  Updates a survey_tool.

  ## Examples

      iex> update_survey_tool(survey_tool, %{field: new_value})
      {:ok, %SurveyTool{}}

      iex> update_survey_tool(survey_tool, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_survey_tool(%SurveyTool{} = survey_tool, attrs) do
    survey_tool
    |> SurveyTool.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a survey_tool.

  ## Examples

      iex> delete_survey_tool(survey_tool)
      {:ok, %SurveyTool{}}

      iex> delete_survey_tool(survey_tool)
      {:error, %Ecto.Changeset{}}

  """
  def delete_survey_tool(%SurveyTool{} = survey_tool) do
    Repo.delete(survey_tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking survey_tool changes.

  ## Examples

      iex> change_survey_tool(survey_tool)
      %Ecto.Changeset{data: %SurveyTool{}}

  """
  def change_survey_tool(%SurveyTool{} = survey_tool, attrs \\ %{}) do
    SurveyTool.changeset(survey_tool, attrs)
  end
end
