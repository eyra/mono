defmodule Systems.Campaign.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    Campaign,
    Promotion,
    Assignment,
    Pool
  }

  @impl true
  def dispatch(signal, %{director: :campaign} = object) do
    handle(signal, object)
  end

  def handle(:survey_tool_updated, survey_tool) do
    experiment = Assignment.Public.get_experiment_by_tool(survey_tool)
    handle(:experiment_updated, experiment)
  end

  def handle(:lab_tool_updated, lab_tool) do
    experiment = Assignment.Public.get_experiment_by_tool(lab_tool)
    handle(:experiment_updated, experiment)
  end

  def handle(:experiment_updated, experiment) do
    assignment = Assignment.Public.get_by_assignable(experiment)
    handle(:assignment_updated, assignment)
  end

  def handle(:assignment_updated, assignment) do
    %{promotion: promotion} =
      campaign =
      Campaign.Public.get_by_promotable(assignment.id, Campaign.Model.preload_graph(:full))

    campaign
    |> Campaign.Presenter.update(promotion.id, Promotion.LandingPage)
    |> Campaign.Presenter.update(assignment.id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end

  def handle(:assignment_accepted, %{assignment: assignment, user: user}) do
    handle(:assignment_updated, assignment)
    Campaign.Public.payout_participant(assignment, user)
  end

  def handle(:assignment_rejected, %{assignment: assignment, user: _user}) do
    handle(:assignment_updated, assignment)
  end

  def handle(:assignment_completed, %{assignment: assignment, user: _user}) do
    handle(:assignment_updated, assignment)
  end

  def handle(:promotion_updated, promotion) do
    campaign = Campaign.Public.get_by_promotion(promotion, Campaign.Model.preload_graph(:full))
    promotable = Campaign.Model.promotable(campaign)

    campaign
    |> Campaign.Presenter.update(promotion.id, Promotion.LandingPage)
    |> Campaign.Presenter.update(promotable.id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end

  def handle(:submission_updated, %Pool.SubmissionModel{} = submission) do
    campaign = Campaign.Public.get_by_submission(submission, Campaign.Model.preload_graph(:full))
    handle(:submission_updated, campaign)
  end

  def handle(
        :submission_updated,
        %Campaign.Model{
          promotion_id: promotion_id,
          promotable_assignment: %{
            id: promotable_assignment_id
          }
        } = campaign
      ) do
    Campaign.Public.submission_updated(campaign)

    campaign
    |> Campaign.Presenter.update(promotion_id, Promotion.LandingPage)
    |> Campaign.Presenter.update(promotable_assignment_id, Assignment.LandingPage)
    |> Campaign.Presenter.update(campaign.id, Campaign.ContentPage)
  end
end
