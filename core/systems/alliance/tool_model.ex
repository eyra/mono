defmodule Systems.Alliance.ToolModel do
  @moduledoc """
  The alliance tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  use Gettext, backend: CoreWeb.Gettext

  require Core.Enums.Devices

  alias Systems.Workflow
  alias Systems.Alliance.VariableParser

  @tool_directors Application.compile_env(:core, :tool_directors)

  schema "alliance_tools" do
    field(:url, :string)
    field(:director, Ecto.Enum, values: @tool_directors)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_one(:tool_ref, Workflow.ToolRefModel, foreign_key: :alliance_tool_id)

    timestamps()
  end

  # fallback needed in preview mode
  @fallback_url "https://unknown.url"

  def safe_uri(%{url: nil}), do: URI.new!(@fallback_url)

  def safe_uri(%{url: url}) do
    case URI.new(url) do
      {:ok, uri} -> uri
      {:error, _} -> URI.new!(@fallback_url)
    end
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(tool), do: tool.auth_node_id
  end

  defimpl Frameworks.Concept.Directable do
    def director(%{director: director}), do: Frameworks.Concept.System.director(director)
  end

  @operational_fields ~w(url)a
  @fields @operational_fields
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @operational_fields

  @impl true
  def operational_validation(changeset), do: changeset

  def preload_graph(:down),
    do:
      preload_graph([
        :auth_node
      ])

  def preload_graph(:auth_node), do: [auth_node: []]

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_url(:url)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end

  def changeset(tool, params) do
    tool
    |> cast(params, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@operational_fields)
  end

  def validate(changeset, :roundtrip) do
    changeset =
      changeset
      |> Ecto.Changeset.validate_required([:url])

    %{changeset | action: :validate_roundtrip}
  end

  def ready?(tool) do
    changeset =
      changeset(tool, %{})
      |> validate()

    changeset.valid?
  end

  def validate_url(%Ecto.Changeset{} = changeset, field, _options \\ []) do
    validate_change(changeset, field, fn _, url ->
      URI.parse(url).query |> validate_query_string(field)
    end)
  end

  def validate_query_string(query, _field) when is_nil(query), do: []

  def validate_query_string(query, field) do
    Enum.flat_map(URI.query_decoder(query), fn {name, value} ->
      case VariableParser.parse(value) do
        {:ok, _, _, _, _, _} ->
          []

        {:error, message, _, _, _, _} ->
          [{field, "Parameter `#{name}` is invalid: #{message}"}]
      end
    end)
  end

  def prepare_url(url, replacements) when is_binary(url) and is_map(replacements) do
    URI.parse(url)
    |> Map.update!(:query, fn query ->
      query
      |> URI.query_decoder()
      |> Enum.map(fn {name, value} ->
        with {:ok, parsed, _, _, _, _} <- VariableParser.parse(value),
             {:ok, [variable]} <- Keyword.fetch(parsed, :variable),
             {:ok, replacement} <-
               Map.fetch(replacements, variable) do
          {name, to_string(replacement)}
        else
          _ ->
            {name, value}
        end
      end)
      |> URI.encode_query()
    end)
    |> to_string()
  end

  def external_path(%{url: url}, next_id)
      when not is_nil(url) do
    url_components = URI.parse(url)

    query =
      url_components.query
      |> decode_query()
      |> Map.put(:next_id, next_id)
      |> URI.encode_query(:rfc3986)

    url_components
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  def external_path(_, _), do: nil

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)

  defimpl Frameworks.Concept.ToolModel do
    use Gettext, backend: CoreWeb.Gettext

    alias Systems.Alliance
    def key(_), do: :alliance
    def auth_tree(%{auth_node: auth_node}), do: auth_node
    def apply_label(_), do: dgettext("eyra-alliance", "apply.cta.title")
    def open_label(_), do: dgettext("eyra-alliance", "open.cta.title")
    def ready?(tool), do: Alliance.ToolModel.ready?(tool)
    def form(_, _), do: Alliance.ToolForm

    def task_labels(_) do
      %{
        pending: dgettext("eyra-alliance", "pending.label"),
        participated: dgettext("eyra-alliance", "participated.label")
      }
    end

    def attention_list_enabled?(_t), do: true
    def group_enabled?(_t), do: false
  end
end
