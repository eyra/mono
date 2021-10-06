defmodule Core.Survey.Tool do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  use Core.Content.Node
  import NimbleParsec

  require Core.Enums.Devices

  import Ecto.Changeset
  alias Core.Studies.Study
  alias Core.Survey.Task
  alias Core.Accounts.User
  alias Core.Promotions.Promotion

  schema "survey_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:study, Study)
    belongs_to(:promotion, Promotion)

    field(:survey_url, :string)
    field(:current_subject_count, :integer)
    field(:subject_count, :integer)
    field(:duration, :string)
    field(:language, :string)
    field(:ethical_approval, :boolean)

    # field(:reward_currency, Ecto.Enum, values: [:eur, :usd, :gbp, :chf, :nok, :sek])
    # field(:reward_value, :integer)
    field(:devices, {:array, Ecto.Enum}, values: Core.Enums.Devices.schema_values())

    has_many(:tasks, Task)
    many_to_many(:participants, User, join_through: :survey_tool_participants)

    timestamps()
  end

  defimpl GreenLight.AuthorizationNode do
    def id(survey_tool), do: survey_tool.auth_node_id
  end

  @fields ~w(survey_url subject_count duration language ethical_approval devices)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @fields

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
    |> cast(params, @fields)
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
