defmodule Systems.Storage.EndpointModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Frameworks.Concept

  alias Systems.{
    Storage
  }

  require Storage.ServiceIds

  @fields ~w()a
  @required_fields @fields
  @special_fields ~w(builtin yoda centerdata aws azure)a

  @derive {Jason.Encoder, only: @special_fields}
  schema "storage_endpoints" do
    belongs_to(:builtin, Storage.BuiltIn.EndpointModel, on_replace: :delete)
    belongs_to(:yoda, Storage.Yoda.EndpointModel, on_replace: :delete)
    belongs_to(:centerdata, Storage.Centerdata.EndpointModel, on_replace: :delete)
    belongs_to(:aws, Storage.AWS.EndpointModel, on_replace: :delete)
    belongs_to(:azure, Storage.Azure.EndpointModel, on_replace: :delete)

    timestamps()
  end

  def changeset(endpoint, params) do
    endpoint
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: @special_fields

  def reset_special(endpoint, special_field, special) when is_atom(special_field) do
    specials =
      Enum.map(
        @special_fields,
        &{&1,
         if &1 == special_field do
           special
         else
           nil
         end}
      )

    changeset(endpoint, %{})
    |> then(
      &Enum.reduce(specials, &1, fn {field, value}, changeset ->
        put_assoc(changeset, field, value)
      end)
    )
  end

  def special(endpoint) do
    if field = special_field(endpoint) do
      Map.get(endpoint, field)
    else
      nil
    end
  end

  def special_field_id(endpoint) do
    if field = special_field(endpoint) do
      map_to_field_id(field)
    else
      nil
    end
  end

  def special_field(endpoint) do
    Enum.reduce(@special_fields, nil, fn field, acc ->
      field_id = map_to_field_id(field)

      if Map.get(endpoint, field_id) != nil do
        field
      else
        acc
      end
    end)
  end

  def ready?(endpoint) do
    if special = special(endpoint) do
      Concept.ContentModel.ready?(special)
    else
      false
    end
  end

  defp map_to_field_id(field), do: String.to_existing_atom("#{field}_id")

  defimpl Frameworks.Concept.ContentModel do
    alias Systems.Storage
    def form(_), do: Storage.EndpointForm
    def ready?(endpoint), do: Storage.EndpointModel.ready?(endpoint)
  end
end
