defmodule Core.NotificationCenter.SignalHandlers do
  use Core.Signals.Handlers
  import Core.NotificationCenter, only: [notify_users_with_role: 3]

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
end
