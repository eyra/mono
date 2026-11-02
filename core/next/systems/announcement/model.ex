defmodule Systems.Announcement.Model do
  @moduledoc """
  An announcement written by a system admin for a group of creators. The body is
  the HTML of the rich-text editor (Trix), stored as the editor sends it.

  `recipient_ids` is the audience, resolved once when it is published
  (`Systems.Announcement.Public.publish_announcement/4`); it does not change after that.
  It can be long, so reads leave it out unless they select it.
  """
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account.User
  alias Systems.Announcement

  @kinds ~w(release_notes)a
  @priorities ~w(normal high)a

  schema "announcement" do
    field(:kind, Ecto.Enum, values: @kinds)
    field(:title, :string)
    field(:summary, :string)
    field(:body, :string)
    field(:priority, Ecto.Enum, values: @priorities, default: :normal)
    field(:published_at, :utc_datetime)
    field(:recipient_ids, {:array, :id}, default: [], load_in_query: false)

    belongs_to(:author, User)
    has_many(:recipients, Announcement.RecipientModel, foreign_key: :announcement_id)

    timestamps()
  end

  @fields ~w(kind title summary body priority)a
  @fixed_after_publishing ~w(kind priority)a

  def kinds, do: @kinds
  def priorities, do: @priorities

  @doc "The fields a save can change."
  def fields, do: @fields

  @doc """
  The fields that can't change once it is published. The audience can't
  either: `recipient_ids` is never cast.
  """
  def fixed_after_publishing, do: @fixed_after_publishing

  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, @fields)
    |> update_change(:body, &blank_without_text/1)
    |> validate_required(@fields)
    |> validate_length(:title, max: 255)
    |> check_constraint(:kind, name: :kind_must_be_valid)
    |> check_constraint(:priority, name: :priority_must_be_valid)
  end

  # A body without visible text, such as one with only empty tags or an image,
  # counts as empty.
  defp blank_without_text(body) do
    if text?(body), do: body, else: ""
  end

  defp text?(html) do
    case Floki.parse_fragment(html) do
      {:ok, tree} -> tree |> Floki.text(style: false) |> String.trim() != ""
      {:error, _} -> false
    end
  end

  def preload_graph(:down), do: preload_graph([:author])
  def preload_graph(:author), do: [author: []]
end
