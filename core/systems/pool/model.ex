defmodule Systems.Pool.Model do
  @moduledoc """
  The pool schema.
  """
  use Frameworks.Utility.Schema

  import Frameworks.Utility.EctoHelper

  alias Core.Accounts.User
  alias Ecto.Changeset

  alias Systems.{
    Pool,
    Budget,
    Content,
    Org
  }

  @icon_type :emoji

  schema "pools" do
    field(:name, :string)
    field(:icon, Frameworks.Utility.EctoTuple)
    field(:virtual_icon, :string, virtual: true)
    field(:target, :integer)
    field(:director, Ecto.Enum, values: [:student, :citizen])
    field(:archived, :boolean, default: false)

    belongs_to(:currency, Budget.CurrencyModel)
    belongs_to(:org, Org.NodeModel)
    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:submissions, Pool.SubmissionModel, foreign_key: :pool_id)

    many_to_many(:participants, User,
      join_through: Pool.ParticipantModel,
      join_keys: [pool_id: :id, user_id: :id]
    )

    timestamps()
  end

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(pool), do: pool.auth_node_id
  end

  @fields ~w(name virtual_icon target director archived)a
  @required_fields @fields

  def prepare(pool) do
    pool
    |> prepare_virtual_icon()
    |> change()
  end

  def change(pool, attrs) do
    pool
    |> prepare_virtual_icon()
    |> cast(attrs, @fields)
    |> apply_virtual_icon_change(@icon_type)
  end

  def validate(changeset, condition \\ true) do
    if condition do
      changeset
      |> validate_required(@required_fields)
    else
      changeset
    end
  end

  def submit(%Changeset{} = changeset), do: changeset

  def submit(%Changeset{} = changeset, %User{id: used_id}, %Budget.CurrencyModel{} = currency) do
    changeset
    |> Changeset.put_assoc(:currency, currency)
    |> Changeset.put_assoc(:auth_node, Core.Authorization.Node.create(used_id, :owner))
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :currency,
        :org,
        :participants,
        :submissions,
        :auth_node
      ])

  def preload_graph(:currency), do: [currency: Budget.CurrencyModel.preload_graph(:full)]
  def preload_graph(:org), do: [org: Org.NodeModel.preload_graph(:full)]
  def preload_graph(:participants), do: [participants: [:profile, :features]]
  def preload_graph(:submissions), do: [submissions: [:criteria]]
  def preload_graph(:auth_node), do: [auth_node: []]

  def labels(pools, active_pool) do
    Enum.map(pools, &label(&1, active_pool))
  end

  def label(%{id: pool_id, org: %{full_name_bundle: full_name_bundle}}, %{id: active_pool_id}) do
    locale = Gettext.get_locale(CoreWeb.Gettext)
    full_name = Content.TextBundleModel.text(full_name_bundle, locale)
    %{id: pool_id, value: full_name, active: pool_id == active_pool_id}
  end

  def title(%__MODULE__{name: name}), do: title(name)
  def title(name) when is_binary(name), do: title(String.split(name, "_"))
  def title(["vu", "sbe" | rest]), do: title(rest)
  def title([element]), do: element

  def title(elements) when is_list(elements) do
    Enum.map_join(elements, " ", &translate(&1))
  end

  def namespace(%{name: name}) do
    name
    |> String.split("_")
    |> Enum.take(2)
    |> Enum.map(&translate(&1))
  end

  defp translate("year" <> year), do: year
  defp translate(element), do: String.upcase(element)
end
