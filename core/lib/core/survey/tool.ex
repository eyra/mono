defmodule Core.Survey.Tool do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  use Core.Content.Node
  import NimbleParsec

  require Core.Enums.Devices

  import Ecto.Changeset

  schema "survey_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:survey_url, :string)
    field(:current_subject_count, :integer)
    field(:subject_count, :integer)
    field(:duration, :string)
    field(:language, :string)
    field(:ethical_approval, :boolean)
    field(:ethical_code, :string)

    field(:devices, {:array, Ecto.Enum}, values: Core.Enums.Devices.schema_values())

    field(:director, Ecto.Enum, values: [:campaign, :assignment])

    timestamps()
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(survey_tool), do: survey_tool.auth_node_id
  end

  @operational_fields ~w(survey_url subject_count duration ethical_code ethical_approval devices)a
  @fields @operational_fields ++ ~w(language)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @operational_fields

  @impl true
  def operational_validation(changeset) do
    validate_true(changeset, :ethical_approval)
  end

  defp validate_true(changeset, field) do
    case get_field(changeset, field) do
      true -> changeset
      _ -> add_error(changeset, field, "is not true")
    end
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_url(:survey_url)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, [:director])
    |> cast(params, @fields)
  end

  def validate(changeset, :roundtrip) do
    changeset =
      changeset
      |> Ecto.Changeset.validate_required([:survey_url])

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
end

defimpl Systems.Assignment.Assignable, for: Core.Survey.Tool do
  import CoreWeb.Gettext

  def languages(%{language: nil}), do: []
  def languages(%{language: language}), do: [language]

  def devices(%{devices: nil}), do: []
  def devices(%{devices: devices}), do: devices

  def spot_count(%{subject_count: nil}), do: 0
  def spot_count(%{subject_count: subject_count}), do: subject_count
  def spot_count(_), do: 0

  def duration(%{duration: nil}), do: 0

  def duration(%{duration: duration}) do
    case Integer.parse(duration) do
      :error -> 0
      {duration, _} -> duration
    end
  end

  def apply_label(_), do: dgettext("link-survey", "apply.cta.title")
  def open_label(_), do: dgettext("link-survey", "open.cta.title")

  def path(%{survey_url: nil}, _), do: nil

  def path(%{survey_url: url}, panl_id) do
    url_components = URI.parse(url)

    query =
      url_components.query
      |> decode_query()
      |> Map.put(:panl_id, panl_id)
      |> URI.encode_query(:rfc3986)

    url_components
    |> Map.put(:query, query)
    |> URI.to_string()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end
