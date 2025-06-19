defmodule Systems.Storage.EndpointModel do
  @fields ~w()a
  @required_fields @fields
  @special_fields ~w(builtin yoda centerdata aws azure)a

  use Ecto.Schema

  use Frameworks.Utility.Schema
  use Frameworks.Concept.Special, @special_fields

  import Ecto.Changeset
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept
  alias Frameworks.Utility.Assets

  alias Systems.Storage
  alias Systems.Monitor

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

  defimpl Frameworks.Concept.Leaf do
    use Gettext, backend: CoreWeb.Gettext

    alias Frameworks.Concept

    def resource_id(%{id: id}), do: "storage/endpoint/#{id}"
    def tag(_), do: dgettext("eyra-storage", "leaf.tag")

    def info(storage_endpoint, _timezone) do
      file_count =
        Monitor.Public.event({storage_endpoint, :files})
        |> Monitor.Public.sum()

      [dngettext("eyra-storage", "1 file", "* files", file_count)]
    end

    def status(%Storage.EndpointModel{} = endpoint) do
      status(Storage.EndpointModel.special(endpoint))
    end

    def status(%Storage.BuiltIn.EndpointModel{}), do: %Concept.Leaf.Status{value: :online}

    def status(special) do
      sum =
        {special, :connected}
        |> Monitor.Public.event()
        |> Monitor.Public.sum()

      if sum <= 0 do
        %Concept.Leaf.Status{value: :concept}
      else
        %Concept.Leaf.Status{value: :online}
      end
    end
  end
end
