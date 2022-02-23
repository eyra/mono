defmodule Systems.DataDonation.PilotModel do
  import CoreWeb.Gettext

  def view_model do
    %{
      researcher: "Dr. Bella Struminskaya",
      pronoun: dgettext("eyra-ui", "pronoun.her"),
      research_topic: "Local processing of digital trace data",
      file_type: "Google Data Package",
      job_title: "Assistant Professor",
      image: "/images/uu_card.svg",
      institution: "University Utrecht"
    }
  end
end
