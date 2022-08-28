defmodule Systems.Campaign.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  @impl true
  def dispatch(:scholar_class_updated, %{
        user: user,
        added_to: added_to_classes,
        deleted_from: deleted_from_classes
      }) do
    Campaign.Context.update_pool_participations(user, added_to_classes, deleted_from_classes)
  end

  @impl true
  def dispatch(signal, %{director: :campaign} = object) do
    handle(signal, object)
  end

  def handle(:survey_tool_updated, survey_tool) do
    experiment = Assignment.Context.get_experiment_by_tool(survey_tool)
    handle(:experiment_updated, experiment)
  end

  def handle(:lab_tool_updated, lab_tool) do
    experiment = Assignment.Context.get_experiment_by_tool(lab_tool)
    handle(:experiment_updated, experiment)
  end

  def handle(:experiment_updated, experiment) do
    assignment = Assignment.Context.get_by_assignable(experiment)
    handle(:assignment_updated, assignment)
  end

  def handle(:assignment_updated, assignment) do
    %{promotion: promotion} =
      campaign =
      Campaign.Context.get_by_promotable(assignment.id, Campaign.Model.preload_graph(:full))

    campaign
    |> Campaign.Presenter.update(promotion.id, Promotion.LandingPage)
    |> Campaign.Presenter.update(assignment.id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end

  def handle(:assignment_accepted, %{assignment: assignment, user: user}) do
    handle(:assignment_updated, assignment)

    if user.student == true do
      Campaign.Context.payout_participant(assignment, user)
    end
  end

  def handle(:assignment_rejected, %{assignment: assignment, user: _user}) do
    handle(:assignment_updated, assignment)
  end

  def handle(:assignment_completed, %{assignment: assignment, user: _user}) do
    handle(:assignment_updated, assignment)
  end

  def handle(:promotion_updated, promotion) do
    campaign = Campaign.Context.get_by_promotion(promotion, Campaign.Model.preload_graph(:full))
    promotable = Campaign.Model.promotable(campaign)

    campaign
    |> Campaign.Presenter.update(promotion.id, Promotion.LandingPage)
    |> Campaign.Presenter.update(promotable.id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end

  def handle(:submission_updated, submission) do
    %{promotion_id: promotion_id, promotable_assignment_id: promotable_assignment_id} =
      campaign =
      Campaign.Context.get_by_submission(submission, Campaign.Model.preload_graph(:full))

    campaign
    |> Campaign.Presenter.update(promotion_id, Promotion.LandingPage)
    |> Campaign.Presenter.update(promotable_assignment_id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end
end
