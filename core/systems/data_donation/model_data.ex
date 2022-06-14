defmodule Systems.DataDonation.ModelData do
  defmodule NoResultsError do
    @moduledoc false
    defexception [:message]
  end

  import CoreWeb.Gettext

  alias Systems.DataDonation.{Model, ResearcherModel, InstitutionModel}

  defp data(),
    do: [
      %Model{
        id: 1,
        recipient: "University Utrecht",
        researcher: %ResearcherModel{
          name: "dr. Bella Struminskaya",
          pronoun: dgettext("eyra-ui", "pronoun.her"),
          job_title: "Assistant Professor",
          institution: %InstitutionModel{
            name: "University Utrecht",
            image: "/images/uu_card.svg"
          }
        },
        research_topic: "Local processing of digital trace data",
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoeveel tijd mensen besteden aan activiteiten (zoals lopen en fietsen) en het verschil hierin voor en tijdens de corona periode.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how much time people spent in activities (such as walking and biking), before and during the COVID-19 pandemic."
        },
        platform: "Google",
        redirect_to: :thanks,
        storage: :s3,
        storage_info: %{key: "google"},
        script: "script.py"
      },
      %Model{
        id: 2,
        recipient: "Centerdata",
        researcher: nil,
        research_topic: "Local processing of digital trace data",
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoeveel tijd mensen besteden aan activiteiten (zoals lopen en fietsen) en het verschil hierin voor en tijdens de corona periode.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how much time people spent in activities (such as walking and biking), before and during the COVID-19 pandemic."
        },
        platform: "Google",
        redirect_to: nil,
        storage: :centerdata,
        storage_info: %{quest: "C_Datadonation_pilot"},
        script: "script.py"
      },
      %Model{
        id: 3,
        recipient: "Universiteit Utrecht",
        researcher: %ResearcherModel{
          name: "dr. Rense Corten",
          pronoun: dgettext("eyra-ui", "pronoun.him"),
          job_title: "Associate Professor",
          institution: %InstitutionModel{
            name: "Universiteit Utrecht",
            image: "/images/uu_card.svg"
          }
        },
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken... <TBD>",
          "en" => "The data that we ask you to donate could be used to investigate... <TBD>"
        },
        platform: "Whatsapp",
        redirect_to: nil,
        storage: :s3,
        storage_info: %{key: "whatsapp_chat"},
        script: "whatsapp_chat.py"
      },
      %Model{
        id: 4,
        recipient: "Universiteit Utrecht",
        researcher: %ResearcherModel{
          name: "dr. Rense Corten",
          pronoun: dgettext("eyra-ui", "pronoun.him"),
          job_title: "Associate Professor",
          institution: %InstitutionModel{
            name: "Universiteit Utrecht",
            image: "/images/uu_card.svg"
          }
        },
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken... <TBD>",
          "en" => "The data that we ask you to donate could be used to investigate... <TBD>"
        },
        platform: "Whatsapp",
        redirect_to: nil,
        storage: :s3,
        storage_info: %{key: "whatsapp_account"},
        script: "whatsapp_account.py"
      }
    ]

  def get("pilot"), do: get(1)

  def get(id) when is_binary(id), do: get(String.to_integer(id))

  def get(id) when is_integer(id) do
    case data() |> Enum.find(&(&1.id == id)) do
      nil -> raise NoResultsError, "Could not find model for data donation flow #{id}"
      value -> value
    end
  end
end

defimpl Plug.Exception, for: Systems.DataDonation.ModelData.NoResultsError do
  def status(_exception), do: 404
  def actions(_), do: []
end
