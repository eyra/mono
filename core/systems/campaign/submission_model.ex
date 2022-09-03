defmodule Systems.Campaign.SubmissionModel do
  @moduledoc """
  A join table to associate campaign with one or more submissions.
  """
  use Ecto.Schema

  alias Systems.{
    Campaign,
    Pool
  }

  schema "campaign_submissions" do
    belongs_to(:campaign, Campaign.Model)
    belongs_to(:submission, Pool.SubmissionModel)

    timestamps()
  end
end
