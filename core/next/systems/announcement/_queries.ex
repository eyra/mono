defmodule Systems.Announcement.Queries do
  import Ecto.Query

  alias Systems.Account.User
  alias Systems.Announcement

  def announcement_query do
    from(a in Announcement.Model, as: :announcement)
  end

  def recipient_query do
    from(r in Announcement.RecipientModel, as: :recipient)
  end

  def recipient_query(%Announcement.Model{id: announcement_id}) do
    recipient_query()
    |> where([recipient: r], r.announcement_id == ^announcement_id)
  end

  def recipient_query(%User{id: user_id}) do
    recipient_query()
    |> where([recipient: r], r.user_id == ^user_id)
  end

  def received_query(%User{} = user) do
    recipient_query(user)
    |> join(:inner, [recipient: r], a in assoc(r, :announcement), as: :announcement)
    |> order_by([announcement: a], desc_nulls_last: a.published_at, desc: a.id)
  end
end
