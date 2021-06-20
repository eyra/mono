defmodule Core.DataDonation.Tools do
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
  alias Core.DataDonation.{Tool, Task}
  alias Core.Authorization

  def list do
    Repo.all(Tool)
  end

  def get!(id), do: Repo.get!(Tool, id)
  def get(id), do: Repo.get(Tool, id)

  def create(attrs, study, promotion, content_node) do
    %Tool{}
    |> Tool.changeset(:mount, attrs)
    |> Ecto.Changeset.put_assoc(:study, study)
    |> Ecto.Changeset.put_assoc(:promotion, promotion)
    |> Ecto.Changeset.put_assoc(:content_node, content_node)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.make_node(study))
    |> Repo.insert()
  end

  def update(changeset) do
    changeset
    |> Repo.update()
  end

  def delete(%Tool{} = tool) do
    study = Core.Studies.get_study!(tool.study_id)
    content_node = Core.Content.Nodes.get!(tool.content_node_id)
    promotion = Core.Promotions.get!(tool.promotion_id)

    Multi.new()
    |> Multi.delete(:study, study)
    |> Multi.delete(:promotion, promotion)
    |> Multi.delete(:content_node, content_node)
    |> Repo.transaction()
  end

  def count_tasks(tool, status_list) do
    case tool.id do
      nil ->
        0

      _ ->
        from(t in Task,
          where: t.data_donation_tool_id == ^tool.id and t.status in ^status_list,
          select: count(t.id)
        )
        |> Repo.one()
    end
  end

  def count_pending_tasks(tool) do
    count_tasks(tool, [:pending])
  end

  def count_completed_tasks(tool) do
    count_tasks(tool, [:completed])
  end

end
