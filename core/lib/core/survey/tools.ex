defmodule Core.Survey.Tools do
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

  alias Core.Survey.Tool
  alias Frameworks.Signal
  alias Core.Content.Nodes

  @doc """
  Returns the list of survey_tools.
  """
  def list_survey_tools do
    Repo.all(Tool)
  end

  @doc """
  Gets a single survey_tool.

  Raises `Ecto.NoResultsError` if the Survey tool does not exist.
  """
  def get_survey_tool!(id), do: Repo.get!(Tool, id)
  def get_survey_tool(id), do: Repo.get(Tool, id)

  @doc """
  Creates a survey_tool.
  """
  def create_survey_tool(attrs, auth_node, content_node) do
    %Tool{}
    |> Tool.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  @doc """
  Updates a survey_tool.
  """
  def update_survey_tool(%Tool{} = survey_tool, type, attrs) do
    survey_tool
    |> Tool.changeset(type, attrs)
    |> update_survey_tool()
  end

  def update_survey_tool(_, _, _), do: nil

  def update_survey_tool(%{data: tool, changes: attrs} = changeset) do
    node = Nodes.get!(tool.content_node_id)
    node_changeset = Tool.node_changeset(node, tool, attrs)

    # campaign_changeset =
    #   Campaign.Model.changeset(campaign, %{updated_at: NaiveDateTime.utc_now()})

    with {:ok, %{tool: tool} = result} <-
           Multi.new()
           |> Multi.update(:tool, changeset)
           |> Multi.update(:content_node, node_changeset)
           |> Repo.transaction() do
      Signal.Context.dispatch!(:survey_tool_updated, tool)
      {:ok, result}
    end
  end

  @doc """
  Deletes a survey_tool.
  """
  def delete_survey_tool(%Tool{} = survey_tool) do
    content_node = Core.Content.Nodes.get!(survey_tool.content_node_id)

    Multi.new()
    |> Multi.delete(:survey_tool, survey_tool)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking survey_tool changes.
  """
  def change_survey_tool(%Tool{} = survey_tool, type, attrs \\ %{}) do
    Tool.changeset(survey_tool, type, attrs)
  end

  def copy(%Tool{} = tool, auth_node, content_node) do
    %Tool{}
    |> Tool.changeset(:copy, Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def ready?(%Tool{} = survey_tool) do
    Nodes.get!(survey_tool.content_node_id).ready
  end
end

defimpl Core.Persister, for: Core.Survey.Tool do
  def save(_tool, changeset) do
    Core.Survey.Tools.update_survey_tool(changeset)
  end
end
