defmodule Systems.DataDonation.ToolModel do
  @moduledoc """
  The data donation tool schema.
  """
  use Ecto.Schema
  use Frameworks.Utility.Model

  require Core.Enums.Themes

  import Ecto.Changeset
  import EctoCommons.URLValidator

  schema "data_donation_tools" do
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

  def store_results(%__MODULE__{} = tool, data) when is_binary(data) do
    storage().store(tool, data)
    # |> S3.upload("eylixir", "path/on/s3")
    # |> ExAws.request()
    # |> IO.inspect()

    # %DataDonation.UserData{}
    # |> DataDonation.UserData.changeset(%{tool: tool, user: user, data: data})
    # |> Repo.insert!()
  end

  defp storage do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end
end
