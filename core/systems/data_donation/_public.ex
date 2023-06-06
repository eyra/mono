defmodule Systems.DataDonation.Public do
  @moduledoc """

  A data donation allows a researcher to ask participants to submit data. This
  data is submitted in the form of a file that is stored on the participants
  device.

  Tools are provided that allow for execution of filtering code on the device
  of the participant. This ensures that only the data that is needed for the
  study is shared with the researcher.
  """

  import Ecto.Query, warn: false
  alias Core.Repo

  alias Ecto.Multi
  alias Core.Authorization

  alias Systems.{
    DataDonation
  }

  def list do
    Repo.all(DataDonation.ToolModel)
  end

  def get(id), do: DataDonation.ModelData.get(id)

  def get_port(id), do: DataDonation.PortModelData.get(id)

  def get_tool!(id), do: Repo.get!(DataDonation.ToolModel, id)
  def get_tool(id), do: Repo.get(DataDonation.ToolModel, id)

  def create(
        %{subject_count: _, director: _} = attrs,
        %Authorization.Node{} = auth_node
      ) do
    %DataDonation.ToolModel{}
    |> DataDonation.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def update(changeset) do
    Multi.new()
    |> Repo.multi_update(:data_donation_tool, changeset)
    |> Repo.transaction()
  end

  def delete(%DataDonation.ToolModel{} = tool) do
    Multi.new()
    |> Multi.delete(:data_donation_tool, tool)
    |> Repo.transaction()
  end

  def list_donations(%DataDonation.ToolModel{} = tool) do
    from(u in DataDonation.UserData,
      where: u.tool_id == ^tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def copy(%DataDonation.ToolModel{} = tool, auth_node) do
    %DataDonation.ToolModel{}
    |> DataDonation.ToolModel.changeset(Map.from_struct(tool))
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert!()
  end
end

defimpl Core.Persister, for: Systems.DataDonation.ToolModel do
  def save(_tool, changeset) do
    case Systems.DataDonation.Public.update(changeset) do
      {:ok, %{data_donation_tool: tool}} -> {:ok, tool}
      _ -> {:error, changeset}
    end
  end
end
