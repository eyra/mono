defmodule Systems.DataDonation.ToolModel do
  @moduledoc """
  The data donation tool schema.
  """
  use Ecto.Schema
  use Core.Content.Node

  require Core.Enums.Themes

  import Ecto.Changeset
  import EctoCommons.URLValidator

  alias Systems.{
    DataDonation
  }

  schema "data_donation_tools" do
    belongs_to(:content_node, Core.Content.Node)
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:script, :string)
    field(:subject_count, :integer)

    field(:director, Ecto.Enum, values: [:assignment])

    timestamps()
  end

  @fields ~w(script reward_currency reward_value subject_count)a
  @required_fields ~w()a

  @impl true
  def operational_fields, do: @fields

  @impl true
  def operational_validation(changeset), do: changeset

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(data_donation_tool), do: data_donation_tool.auth_node_id
  end

  def changeset(tool, :mount, params) do
    tool
    |> cast(params, [:director])
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
    %DataDonation.UserData{}
    |> DataDonation.UserData.changeset(%{tool: tool, user: user, data: data})
    |> Repo.insert!()
  end
end

defimpl Systems.Assignment.Assignable, for: Systems.DataDonation.ToolModel do
  import CoreWeb.Gettext

  def languages(_), do: []
  def devices(_), do: []
  def spot_count(%{subject_count: nil}), do: 0
  def spot_count(%{subject_count: subject_count}), do: subject_count
  def spot_count(_), do: 0
  def duration(_), do: 0
  def path(_, _), do: nil
  def apply_label(_), do: dgettext("eyra-data-donation", "apply.cta.title")
  def open_label(_), do: dgettext("eyra-data-donation", "open.cta.title")
end
