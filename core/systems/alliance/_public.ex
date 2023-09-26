defmodule Systems.Alliance.Public do
  @moduledoc """

  Alliance tools allow a researcher to setup a link to an external web
  tool. The participant goes through the flow described below:

  - Receive invitation to start a alliance (mail, push etc.).
  - Open alliance tool, this opens it on the platform and requires authentication.
  - The participant is then redirected to the alliance at a 3rd party web-application.
  - After completion the user is redirect back to the platform.
  - The platform registers the completion of this alliance for the participant.


  A researcher is required to configure the 3rd party application with a redirect
  link. The redirect link to be used is show on the alliance tool configuration
  screen (with copy button).

  IDEA: The tool requires a sucessful round-trip with a verify flow to ensure
  that everything is configured correctly.

  Participants need to be invited to a particular alliance explicitly. This avoids
  the situation where a new user joins a study and then can immediately complete
  previous alliances.

  Once a participant has completed a alliance they are no longer allowed to enter it
  a second time. The status is clearly shown when the attempt to do so.

  IDEA: A list of alliances can be access by the notification icon which is shown
  on all screens.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Core.Repo

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Alliance
  }

  @doc """
  Returns the list of alliance_tools.
  """
  def list_tools do
    Repo.all(Alliance.ToolModel)
  end

  @doc """
  Gets a single alliance_tool.

  Raises `Ecto.NoResultsError` if the Alliance tool does not exist.
  """
  def get_tool!(id), do: Repo.get!(Alliance.ToolModel, id)
  def get_tool(id), do: Repo.get(Alliance.ToolModel, id)

  @doc """
  Creates a alliance_tool.
  """
  def prepare_tool(attrs, auth_node \\ Core.Authorization.make_node()) do
    %Alliance.ToolModel{}
    |> Alliance.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  @doc """
  Updates a alliance_tool.
  """
  def update_tool(%Alliance.ToolModel{} = alliance_tool, type, attrs) do
    alliance_tool
    |> Alliance.ToolModel.changeset(type, attrs)
    |> update_tool()
  end

  def update_tool(_, _, _), do: {:error, nil}

  def update_tool(changeset) do
    result =
      Multi.new()
      |> Repo.multi_update(:tool, changeset)
      |> Repo.transaction()

    with {:ok, %{tool: tool}} <- result do
      Signal.Public.dispatch!(:alliance_tool, %{tool: tool})
    end

    result
  end

  @doc """
  Deletes a alliance_tool.
  """
  def delete_tool(%Alliance.ToolModel{} = alliance_tool) do
    Repo.delete(alliance_tool)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alliance_tool changes.
  """
  def change_tool(
        %Alliance.ToolModel{} = alliance_tool,
        type,
        attrs \\ %{}
      ) do
    Alliance.ToolModel.changeset(alliance_tool, type, attrs)
  end

  def copy(%Alliance.ToolModel{} = tool, auth_node) do
    %Alliance.ToolModel{}
    |> Alliance.ToolModel.changeset(:copy, Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end

  def ready?(%Alliance.ToolModel{} = alliance_tool) do
    changeset =
      %Alliance.ToolModel{}
      |> Alliance.ToolModel.operational_changeset(Map.from_struct(alliance_tool))

    changeset.valid?
  end
end

defimpl Core.Persister, for: Systems.Alliance.ToolModel do
  def save(_tool, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :alliance_tool) do
      {:ok, %{alliance_tool: alliance_tool}} -> {:ok, alliance_tool}
      _ -> {:error, changeset}
    end
  end
end
