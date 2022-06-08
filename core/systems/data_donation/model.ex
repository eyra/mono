defmodule Systems.DataDonation.Model do
  use Ecto.Schema

  embedded_schema do
    field(:recipient, :string)
    field(:research_topic, :string)
    field(:research_description, :map)
    field(:platform, :string)
    field(:redirect_to, :string)
    field(:storage, :string)
    field(:storage_info, :map)
    field(:script, :string)

    embeds_one(:researcher, Systems.DataDonation.ResearcherModel)
  end
end
