defmodule Systems.DataDonation.ResearcherModel do
  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:pronoun, :string)
    field(:job_title, :string)

    embeds_one(:institution, Systems.DataDonation.InstitutionModel)
  end
end
