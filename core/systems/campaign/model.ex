defmodule Systems.Campaign.Model do
  @moduledoc """
  The campaign type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "studies" do
    field(:description, :string)
    field(:title, :string)

    belongs_to(:auth_node, Core.Authorization.Node)

    has_many(:role_assignments, through: [:auth_node, :role_assignments])

    has_many(:authors, Systems.Campaign.AuthorModel, foreign_key: :study_id)
    has_many(:participants, Systems.Campaign.Participant, foreign_key: :study_id)
    has_one(:survey_tool, Core.Survey.Tool, foreign_key: :study_id)
    has_one(:lab_tool, Core.Lab.Tool, foreign_key: :study_id)
    has_one(:data_donation_tool, Core.DataDonation.Tool, foreign_key: :study_id)

    timestamps()
  end

  @required_fields ~w(title)a
  @optional_fields ~w(description updated_at)a
  @fields @required_fields ++ @optional_fields

  defimpl GreenLight.AuthorizationNode do
    def id(campaign), do: campaign.auth_node_id
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
