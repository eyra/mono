defmodule Systems.Storage.EndpointModel do
  use Ecto.Schema
  alias Frameworks.Utility.Assets
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import CoreWeb.Gettext

  alias Frameworks.Concept

  alias Systems.{
    Storage
  }

  require Storage.ServiceIds

  schema "storage_endpoints" do
    belongs_to(:auth_node, Core.Authorization.Node)

    belongs_to(:builtin, Storage.BuiltIn.EndpointModel, on_replace: :delete)
    belongs_to(:yoda, Storage.Yoda.EndpointModel, on_replace: :delete)
    belongs_to(:centerdata, Storage.Centerdata.EndpointModel, on_replace: :delete)
    belongs_to(:aws, Storage.AWS.EndpointModel, on_replace: :delete)
    belongs_to(:azure, Storage.Azure.EndpointModel, on_replace: :delete)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields
  @special_fields ~w(builtin yoda centerdata aws azure)a

  use Frameworks.Concept.Special, @special_fields

  @spec changeset(
          {map(), map()}
          | %{
              :__struct__ => atom() | %{:__changeset__ => map(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  def changeset(endpoint, params) do
    endpoint
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: @special_fields ++ [:auth_node]

  def auth_tree(%{auth_node: auth_node}), do: auth_node

  def tag(_) do
    dgettext("eyra-storage", "project.item.tag")
  end

  def ready?(endpoint) do
    if special = special(endpoint) do
      Concept.ContentModel.ready?(special)
    else
      false
    end
  end

  def asset_image_src(%Storage.EndpointModel{} = endpoint, type) do
    asset_image_src(special_field(endpoint), type)
  end

  def asset_image_src(:builtin, type), do: Assets.image_src("next", type)
  def asset_image_src(special, type), do: Assets.image_src("#{special}", type)

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(endpoint), do: endpoint.auth_node_id
  end

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage
    def form(_), do: Storage.EndpointForm
    def ready?(endpoint), do: Storage.EndpointModel.ready?(endpoint)
  end
end
