defmodule Systems.DataDonation.Model do
  use Ecto.Schema

  embedded_schema do
    field(:researcher, :string)
    field(:pronoun, :string)
    field(:research_topic, :string)
    field(:file_type, :string)
    field(:job_title, :string)
    field(:image, :string)
    field(:institution, :string)
    field(:redirect_to, :string)
    field(:storage, :string)
    field(:storage_info, :map)
    field(:script, :string)
  end
end
