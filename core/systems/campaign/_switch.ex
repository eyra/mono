defmodule Systems.Campaign.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  @impl true
  def intercept({:assignment, _} = signal, %{assignment: assignment} = message) do
    if campaign =
         Campaign.Public.get_by_promotable(assignment, Campaign.Model.preload_graph(:down)) do
      handle(signal, message)
      dispatch!({:campaign, signal}, Map.merge(message, %{campaign: campaign}))
    end

    :ok
  end

  @impl true
  def intercept({:promotion, _} = signal, %{promotion: promotion} = message) do
    if campaign = Campaign.Public.get_by_promotion(promotion, Campaign.Model.preload_graph(:down)) do
      dispatch!({:campaign, signal}, Map.merge(message, %{campaign: campaign}))
    end

    :ok
  end

  @impl true
  def intercept({:campaign, _} = signal, message) do
    handle(signal, message)
    :ok
  end

  @impl true
  def intercept({:user_profile, _} = signal, message) do
    handle(signal, message)
    :ok
  end

  # HANDLE

  defp handle({:user_profile, :updated}, %{user: user, user_changeset: user_changeset}) do
    if Map.has_key?(user_changeset.changes, :coordinator) do
      new_value = user_changeset.changes.coordinator
      Campaign.Public.update_coordinator_role(user, new_value)
    end
  end

  defp handle(
         {:campaign, event},
         %{
           campaign:
             %Campaign.Model{
               id: id,
               promotion_id: promotion_id,
               promotable_assignment_id: assignment_id
             } = campaign,
           from_pid: from_pid
         }
       ) do
    if event == :created do
      Campaign.Public.assign_coordinators(campaign)
    else
      update(Promotion.LandingPage, promotion_id, campaign, from_pid)
      update(Assignment.LandingPage, assignment_id, campaign, from_pid)
      update(Campaign.ContentPage, id, campaign, from_pid)
    end
  end

  defp handle({_, _}, _), do: nil

  def update(page, id, %Campaign.Model{} = campaign, from_pid) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: campaign, from_pid: from_pid})
  end
end
