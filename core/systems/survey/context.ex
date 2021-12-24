defmodule Systems.Survey.Context do
  @moduledoc """

  Survey tools allow a researcher to setup a link to an external survey
  tool. The participant goes through the flow described below:

  - Receive invitation to start a survey (mail, push etc.).
  - Open survey tool, this opens it on the platform and requires authentication.
  - The participant is then redirected to the survey at a 3rd party web-application.
  - After completion the user is redirect back to the platform.
  - The platform registers the completion of this survey for the participant.


  A researcher is required to configure the 3rd party application with a redirect
  link. The redirect link to be used is show on the survey tool configuration
  screen (with copy button).

  IDEA: The tool requires a sucessful round-trip with a verify flow to ensure
  that everything is configured correctly.

  Participants need to be invited to a particular survey explicitly. This avoids
  the situation where a new user joins a study and then can immediately complete
  previous surveys.

  Once a participant has completed a survey they are no longer allowed to enter it
  a second time. The status is clearly shown when the attempt to do so.

  IDEA: A list of surveys can be access by the notification icon which is shown
  on all screens.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Core.Repo

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Survey
  }

  @doc """
  Returns the list of survey_tools.
  """
  def list_survey_tools do
    Repo.all(Survey.ToolModel)
  end

  @doc """
  Gets a single survey_tool.

  Raises `Ecto.NoResultsError` if the Survey tool does not exist.
  """
  def get_survey_tool!(id), do: Repo.get!(Survey.ToolModel, id)
  def get_survey_tool(id), do: Repo.get(Survey.ToolModel, id)

  @doc """
  Creates a survey_tool.
  """
  def create_tool(attrs, auth_node) do
    %Survey.ToolModel{}
    |> Survey.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  @doc """
  Updates a survey_tool.
  """
  def update_survey_tool(%Survey.ToolModel{} = survey_tool, type, attrs) do
    survey_tool
    |> Survey.ToolModel.changeset(type, attrs)
    |> update_survey_tool()
  end

  def update_survey_tool(_, _, _), do: nil

  def update_survey_tool(changeset) do
    with {:ok, %{tool: tool} = result} <-
           Multi.new()
           |> Multi.update(:tool, changeset)
           |> Repo.transaction()
           do
      Signal.Context.dispatch!(:survey_tool_updated, tool)
      {:ok, result}
    end
  end

  @doc """
  Deletes a survey_tool.
  """
  def delete_survey_tool(%Survey.ToolModel{} = survey_tool) do
    Repo.delete(survey_tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking survey_tool changes.
  """
  def change_survey_tool(%Survey.ToolModel{} = survey_tool, type, attrs \\ %{}) do
    Survey.ToolModel.changeset(survey_tool, type, attrs)
  end

  def copy(%Survey.ToolModel{} = tool, auth_node) do
    %Survey.ToolModel{}
    |> Survey.ToolModel.changeset(:copy, Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def ready?(%Survey.ToolModel{} = survey_tool) do
    changeset =
      %Survey.ToolModel{}
      |> Survey.ToolModel.operational_changeset(Map.from_struct(survey_tool))

    changeset.valid?
  end
end

defimpl Core.Persister, for: Systems.Survey.ToolModel do
  def save(_tool, changeset) do
    Systems.Survey.Context.update_survey_tool(changeset)
  end
end
