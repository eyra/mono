defmodule Core.Survey.Tool do
  @moduledoc """
  The survey tool schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  require Core.Devices
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
    field(:subject_count, :integer)
    field(:duration, :string)
    field(:reward_currency, Ecto.Enum, values: [:eur, :usd, :gbp, :chf, :nok, :sek])
    field(:reward_value, :integer)
    field(:devices, {:array, Ecto.Enum}, values: Core.Devices.device_values())

    has_many(:tasks, Task)
    many_to_many(:participants, User, join_through: :survey_tool_participants)

    timestamps()
  end

  defimpl GreenLight.AuthorizationNode do
    def id(survey_tool), do: survey_tool.auth_node_id
  end

  @fields ~w(survey_url subject_count duration reward_currency reward_value devices)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @fields

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def changeset(tool, _, params) do
    tool
    |> cast(params, @fields)
  end
end
