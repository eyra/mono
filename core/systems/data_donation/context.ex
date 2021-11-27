defmodule Systems.DataDonation.Context do
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
  alias Core.Content.Nodes

  alias Systems.{
    DataDonation
  }

  def list do
    Repo.all(DataDonation.ToolModel)
  end

  def get!(id), do: Repo.get!(DataDonation.ToolModel, id)
  def get(id), do: Repo.get(DataDonation.ToolModel, id)

  def get_by_promotion(promotion_id) do
    from(t in DataDonation.ToolModel,
      where: t.promotion_id == ^promotion_id
    )
    |> Repo.one()
  end

  def create(attrs, campaign, promotion, content_node) do
    %DataDonation.ToolModel{}
    |> DataDonation.ToolModel.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:campaign, campaign)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(campaign))
    |> Repo.insert()
  end

  def update(%{data: tool, changes: attrs} = changeset) do
    node = Nodes.get!(tool.content_node_id)
    node_changeset = DataDonation.ToolModel.node_changeset(node, tool, attrs)

    Multi.new()
    |> Multi.update(:tool, changeset)
    |> Multi.update(:content_node, node_changeset)
    |> Repo.transaction()
  end

  def delete(%DataDonation.ToolModel{} = tool) do
    content_node = Core.Content.Nodes.get!(tool.content_node_id)

    Multi.new()
    |> Multi.delete(:data_donation_tool, tool)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  def list_donations(%DataDonation.ToolModel{} = tool) do
    from(u in DataDonation.UserData,
      where: u.tool_id == ^tool.id,
      preload: [:user]
    )
    |> Repo.all()
  end
end

defimpl Core.Persister, for: Systems.DataDonation.ToolModel do
  def save(_tool, changeset) do
    Systems.DataDonation.Context.update(changeset)
  end
end
