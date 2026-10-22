defmodule Systems.Zircon.Screening.SessionModel do
  @moduledoc """
  Model for the screening process.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Systems.Zircon
  alias Systems.Account

  schema "zircon_screening_session" do
    field(:identifier, :string)
    field(:agent_state, :map)

    # invalidated_at is set when the snapshot is outdated and needs to be updated
    field(:invalidated_at, :naive_datetime)

    belongs_to(:user, Account.User)
    belongs_to(:tool, Zircon.Screening.ToolModel)

    timestamps()
  end

  @fields ~w(identifier agent_state invalidated_at)a
  @required_fields ~w(identifier)a

  def changeset(session, attrs) do
    cast(session, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: preload_graph([:user, :tool])

  def preload_graph(:up), do: []

  def preload_graph(:tool), do: [tool: Zircon.Screening.ToolModel.preload_graph(:down)]
  def preload_graph(:user), do: [user: []]
end
