defmodule Systems.NotificationCenter.Switch do
  use Core.Signals.Handlers
  import Ecto.Query
  alias Core.Repo

  import Systems.NotificationCenter,
    only: [notify: 2, notify_users_with_role: 3, mark_as_notified: 2, marked_as_notified?: 2]

  alias Core.Accounts.User
  alias Core.Studies
  alias Core.Promotions

  @impl true
  def dispatch(:participant_applied, %{tool: %{study_id: study_id, promotion_id: promotion_id}}) do
    study = Studies.get_study!(study_id)
    promotion = Promotions.get!(promotion_id)

    notify_users_with_role(study, :owner, %{
      title: "New participant for: #{promotion.title}"
    })
  end

  @impl true
  def dispatch(:submission_accepted, %{submission: submission}) do
    unless marked_as_notified?(submission, :submission_accepted) do
      query = from(u in User, where: u.student)
      stream = Repo.stream(query)

      Repo.transaction(fn ->
        notify_users(stream, %{title: "New study available"})

        mark_as_notified(submission, :submission_accepted)
      end)
    end
  end

  defp notify_users(users, message) do
    Enum.each(users, fn user ->
      notify(user, message)
    end)
  end
end
