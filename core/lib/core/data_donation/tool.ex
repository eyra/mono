defmodule Core.DataDonation.Tool do
  @moduledoc """
  The data donation tool schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  require Core.Enums.Themes

  import Ecto.Changeset
  import EctoCommons.URLValidator

  alias Core.Studies.Study
  alias Core.Accounts.User
  alias Core.Promotions.Promotion
  alias Core.DataDonation.UserData

  schema "data_donation_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)
    belongs_to(:study, Study)
    belongs_to(:promotion, Promotion)

    field(:script, :string)
    field(:reward_currency, Ecto.Enum, values: [:eur, :usd, :gbp, :chf, :nok, :sek])
    field(:reward_value, :integer)
    field(:subject_count, :integer)

    has_many(:tasks, Core.DataDonation.Task)
    many_to_many(:participants, User, join_through: :data_donation_participants)

    timestamps()
  end

  @fields ~w(script reward_currency reward_value subject_count)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @fields

  defimpl GreenLight.AuthorizationNode do
    def id(data_donation_tool), do: data_donation_tool.auth_node_id
  end

  def changeset(tool, :mount, params) do
    tool
    |> cast(params, @fields)
  end

  def changeset(tool, :auto_save, params) do
    tool
    |> cast(params, @fields)
    |> validate_required(@required_fields)
    |> validate_optional_number(:subject_count, greater_than: 0)
  end

  def validate_optional_number(changeset, field, opts) do
    if blank?(changeset, field) do
      changeset
    else
      changeset |> validate_number(field, opts)
    end
  end

  defp blank?(changeset, field) do
    %{changes: changes} = changeset
    value = Map.get(changes, field)
    blank?(value)
  end

  def store_results(%__MODULE__{} = tool, user, data) when is_binary(data) do
    %UserData{}
    |> UserData.changeset(%{tool: tool, user: user, data: data})
    |> Repo.insert!()
  end
end
