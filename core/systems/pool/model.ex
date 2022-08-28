defmodule Systems.Pool.Model do
  @moduledoc """
  The pool schema.
  """
  use Frameworks.Utility.Schema

  alias Core.Accounts.User

  alias Systems.{
    Pool,
    Budget,
    Content,
    Org
  }

  schema "pools" do
    field(:name, :string)
    field(:target, :integer)
    belongs_to(:currency, Budget.CurrencyModel)
    belongs_to(:org, Org.NodeModel)

    has_many(:submissions, Pool.SubmissionModel, foreign_key: :pool_id)

    many_to_many(:participants, User,
      join_through: Pool.ParticipantModel,
      join_keys: [pool_id: :id, user_id: :id]
    )

    timestamps()
  end

  def preload_graph(:full),
    do:
      preload_graph([
        :currency,
        :org,
        :participants,
        :submissions
      ])

  def preload_graph(:currency), do: [currency: Budget.CurrencyModel.preload_graph(:full)]
  def preload_graph(:org), do: [org: Org.NodeModel.preload_graph(:full)]
  def preload_graph(:participants), do: [participants: [:profile, :features]]
  def preload_graph(:submissions), do: [submissions: [:criteria]]

  def labels(pools, active_pool) do
    Enum.map(pools, &label(&1, active_pool))
  end

  def label(%{id: pool_id, org: %{full_name_bundle: full_name_bundle}}, %{id: active_pool_id}) do
    locale = Gettext.get_locale(CoreWeb.Gettext)
    full_name = Content.TextBundleModel.text(full_name_bundle, locale)
    %{id: pool_id, value: full_name, active: pool_id == active_pool_id}
  end

  def title(%{name: name}) do
    name
    |> String.split("_")
    |> Enum.drop(2)
    |> Enum.map_join(" ", &translate(&1))
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
