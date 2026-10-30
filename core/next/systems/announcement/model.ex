defmodule Next.Announcement.Model do
  @moduledoc """
  An announcement written by a system admin for a group of creators. The body is
  Trix HTML, cleaned by `Next.Announcement.Scrubber` on every save.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Next.Announcement
  alias Systems.Account.User

  @kinds ~w(release_notes)a
  @priorities ~w(normal high)a

  schema "announcement" do
    field(:kind, Ecto.Enum, values: @kinds)
    field(:title, :string)
    field(:summary, :string)
    field(:body, :string)
    field(:priority, Ecto.Enum, values: @priorities, default: :normal)
    field(:published_at, :utc_datetime)

    belongs_to(:author, User)
    has_many(:recipients, Announcement.RecipientModel, foreign_key: :announcement_id)

    timestamps()
  end

  @fields ~w(kind title summary body priority)a

  def kinds, do: @kinds
  def priorities, do: @priorities

  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, @fields)
    |> update_change(:body, &Announcement.Scrubber.sanitize/1)
    |> validate_required(@fields)
    |> check_constraint(:kind, name: :kind_must_be_valid)
    |> check_constraint(:priority, name: :priority_must_be_valid)
  end

  def preload_graph(:down), do: preload_graph([:author])
  def preload_graph(:author), do: [author: []]
end
