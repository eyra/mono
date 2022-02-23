defmodule Systems.DataDonation.PilotModel do
  import CoreWeb.Gettext

  def view_model do
    %{
      researcher: "dr. Bella Struminskaya",
      pronoun: dgettext("eyra-ui", "pronoun.her"),
      research_topic: "Local processing of digital trace data",
      file_type: "Google",
      job_title: "Assistant Professor",
      image: "/images/uu_card.svg",
      institution: "University Utrecht"
    }
  end
end
