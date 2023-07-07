defmodule Systems.Questionnaire.ToolModel do
  @moduledoc """
  The questionnaire tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model
  use Frameworks.Utility.Schema

  import NimbleParsec

  require Core.Enums.Devices

  import Ecto.Changeset

  schema "questionnaire_tools" do
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:questionnaire_url, :string)
    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(questionnaire_tool), do: questionnaire_tool.auth_node_id
  end

  @operational_fields ~w(questionnaire_url)a
  @fields @operational_fields
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @operational_fields

  @impl true
  def operational_validation(changeset), do: changeset

  def preload_graph(:full),
    do:
      preload_graph([
        :auth_node
      ])

  def preload_graph(:auth_node), do: [auth_node: []]

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_url(:questionnaire_url)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end

  def validate(changeset, :roundtrip) do
    changeset =
      changeset
      |> Ecto.Changeset.validate_required([:questionnaire_url])

    %{changeset | action: :validate_roundtrip}
  end

  variable =
    string("<")
    |> ignore()
    |> utf8_string(
      [?a..?z, ?A..?Z],
      min: 1
    )
    |> tag(:variable)
    |> concat(
      string(">")
      |> ignore()
    )
    |> label("variable (ex. <participantId>)")

  non_variable =
    repeat(ascii_char([{:not, ?<}, {:not, ?>}]))
    |> tag(:plain)
    |> label("plain")

  defparsec(:variable_parser, choice([variable, non_variable]) |> eos())

  def validate_url(%Ecto.Changeset{} = changeset, field, _options \\ []) do
    validate_change(changeset, field, fn _, url ->
      URI.parse(url).query |> validate_query_string(field)
    end)
  end

  def validate_query_string(query, _field) when is_nil(query), do: []

  def validate_query_string(query, field) do
    Enum.flat_map(URI.query_decoder(query), fn {name, value} ->
      case variable_parser(value) do
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
        with {:ok, parsed, _, _, _, _} <- variable_parser(value),
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

  def external_path(%{questionnaire_url: questionnaire_url}, panl_id)
      when not is_nil(questionnaire_url) do
    url_components = URI.parse(questionnaire_url)

    query =
      url_components.query
      |> decode_query()
      |> Map.put(:panl_id, panl_id)
      |> URI.encode_query(:rfc3986)

    url_components
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  def external_path(_, _), do: nil

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
