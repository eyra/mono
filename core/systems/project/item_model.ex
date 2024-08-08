defmodule Systems.Project.ItemModel do
  @required_fields ~w(name project_path)a
  @fields @required_fields
  @special_fields ~w(storage_endpoint assignment advert leaderboard)a

  use Ecto.Schema
  use Frameworks.Utility.Schema
  use Frameworks.Concept.Special, @special_fields

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Core.ImageHelpers
  alias Frameworks.Concept

  alias Systems.Project
  alias Systems.Storage
  alias Systems.Assignment
  alias Systems.Advert
  alias Systems.Graphite

  schema "project_items" do
    field(:name, :string)
    field(:project_path, {:array, :integer})
    belongs_to(:node, Project.NodeModel)
    belongs_to(:storage_endpoint, Storage.EndpointModel)
    belongs_to(:assignment, Assignment.Model)
    belongs_to(:advert, Advert.Model)
    belongs_to(:leaderboard, Graphite.LeaderboardModel)
    timestamps()
  end

  @doc false
  def changeset(project_item, attrs) do
    project_item
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:up),
    do:
      preload_graph([
        :node
      ])

  def preload_graph(:down),
    do:
      preload_graph([
        :assignment,
        :leaderboard,
        :advert,
        :storage_endpoint
      ])

  def preload_graph(:node), do: [node: [:parent, :children, :items, :auth_node]]
  def preload_graph(:assignment), do: [assignment: Assignment.Model.preload_graph(:down)]

  def preload_graph(:leaderboard),
    do: [leaderboard: Graphite.LeaderboardModel.preload_graph(:down)]

  def preload_graph(:advert),
    do: [advert: Advert.Model.preload_graph(:down)]

  def preload_graph(:storage_endpoint),
    do: [storage_endpoint: Storage.EndpointModel.preload_graph(:down)]

  def auth_tree(%Project.ItemModel{assignment: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :assignment))
  end

  def auth_tree(%Project.ItemModel{assignment: assignment}) when not is_nil(assignment) do
    Assignment.Model.auth_tree(assignment)
  end

  def auth_tree(%Project.ItemModel{leaderboard: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :leaderboard))
  end

  def auth_tree(%Project.ItemModel{leaderboard: leaderboard}) when not is_nil(leaderboard) do
    Graphite.LeaderboardModel.auth_tree(leaderboard)
  end

  def auth_tree(%Project.ItemModel{advert: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :advert))
  end

  def auth_tree(%Project.ItemModel{advert: advert}) when not is_nil(advert) do
    Advert.Model.auth_tree(advert)
  end

  def auth_tree(%Project.ItemModel{storage_endpoint: %Ecto.Association.NotLoaded{}} = item) do
    auth_tree(Repo.preload(item, :storage_endpoint))
  end

  def auth_tree(%Project.ItemModel{storage_endpoint: storage_endpoint})
      when not is_nil(storage_endpoint) do
    Storage.EndpointModel.auth_tree(storage_endpoint)
  end

  def auth_tree(items) when is_list(items) do
    Enum.map(items, &auth_tree/1)
  end

  defimpl Frameworks.Concept.Leaf do
    def tag(item), do: Project.ItemModel.special(item) |> Concept.Leaf.tag()
    def resource_id(item), do: Project.ItemModel.special(item) |> Concept.Leaf.resource_id()
    def info(item, timezone), do: Project.ItemModel.special(item) |> Concept.Leaf.info(timezone)
    def status(item), do: Project.ItemModel.special(item) |> Concept.Leaf.status()
  end

  defimpl Frameworks.Utility.ViewModelBuilder do
    use CoreWeb, :verified_routes

    def view_model(
          %Project.ItemModel{id: id, name: name} = item,
          {Project.NodePage, :item_card},
          %{timezone: timezone}
        ) do
      %{
        type: :secondary,
        id: id,
        title: name,
        path: "/#{Concept.Leaf.resource_id(item)}/content",
        image_info: image_info(item),
        icon_url: logo_url(item),
        label: label(Concept.Leaf.status(item)),
        tags: [Concept.Leaf.tag(item)],
        info: Concept.Leaf.info(item, timezone),
        left_actions: left_actions(item),
        right_actions: right_actions(item)
      }
    end

    # ACTIONS

    defp left_actions(%Project.ItemModel{id: id}) do
      edit = %{
        action: %{type: :send, event: "rename", item: id},
        face: %{type: :label, label: "Rename", wrap: true}
      }

      [edit]
    end

    defp right_actions(%Project.ItemModel{id: id}) do
      delete = %{
        action: %{type: :send, event: "delete", item: id},
        face: %{type: :icon, icon: :delete}
      }

      [delete]
    end

    # IMAGE

    defp image_info(%Project.ItemModel{} = item) do
      image_info(Project.ItemModel.special(item))
    end

    defp image_info(%Storage.EndpointModel{}) do
      image_info(
        "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1622986819498-60765a6e52c0%3Fixid%3DM3w1MzYyOTF8MHwxfHNlYXJjaHwzOXx8Zm9sZGVyc3xlbnwwfHx8fDE3MTg3OTEyOTB8MA%26ixlib%3Drb-4.0.3&username=_sycthe_&name=Tanay+Shah&blur_hash=LCH%5En%5DActRkV%2AH%25yM%7BsD%5BBNMkYkU"
      )
    end

    defp image_info(%Assignment.Model{info: %{image_id: image_id}}) do
      image_info(image_id)
    end

    defp image_info(struct) when is_struct(struct) do
      image_info(assignment(struct))
    end

    defp image_info(image_id) do
      ImageHelpers.get_image_info(image_id, 400, 200)
    end

    # LOGO

    defp logo_url(%Project.ItemModel{} = item) do
      logo_url(Project.ItemModel.special(item))
    end

    defp logo_url(%Storage.EndpointModel{} = storage_endpoint) do
      Storage.EndpointModel.asset_image_src(storage_endpoint, :icon)
    end

    defp logo_url(%Assignment.Model{info: %{logo_url: logo_url}}) do
      logo_url
    end

    defp logo_url(struct) when is_struct(struct) do
      logo_url(assignment(struct))
    end

    defp logo_url(nil), do: nil

    # LABEL
    defp label(%Frameworks.Concept.Leaf.Status{value: status}),
      do: label(status)

    defp label(:concept),
      do: %{type: :warning, text: dgettext("eyra-project", "label.concept")}

    defp label(:online), do: %{type: :success, text: dgettext("eyra-project", "label.online")}

    defp label(:offline),
      do: %{type: :delete, text: dgettext("eyra-project", "label.offline")}

    defp label(:idle),
      do: %{type: :idle, text: dgettext("eyra-project", "label.idle")}

    # STRUCTURE

    defp assignment(%Project.ItemModel{} = item) do
      assignment(Project.ItemModel.special(item))
    end

    defp assignment(%Graphite.LeaderboardModel{tool: tool}) do
      assignment(Assignment.Public.get_by_tool(tool, [:info]))
    end

    defp assignment(%Advert.Model{assignment: assignment}), do: assignment
    defp assignment(%Assignment.Model{} = assignment), do: assignment
  end
end
