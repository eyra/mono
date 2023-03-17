defmodule Systems.DataDonation.ModelData do
  defmodule NoResultsError do
    @moduledoc false
    defexception [:message]
  end

  alias Systems.DataDonation.Model

  defp data(),
    do: [
      %Model{
        id: 5,
        recipient: "LISS panel",
        researcher: nil,
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoe mensen WhatsApp groepen gebruiken. Gegevens, zoals aantal berichten per persoon, zullen uit uw WhatsApp groep bestand gehaald worden. Dit zijn echter geen gegevens die te herleiden zijn naar personen.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how people use WhatsApp groups. Information, such as number of messages per person, will be extracted from your WhatsApp group data. However, no personal identifiable information will be extracted."
        },
        platform: "WhatsApp",
        redirect_to: :thanks_whatsapp,
        storage: :s3,
        storage_info: %{key: "whatsapp_chat_liss"},
        script: "whatsapp_chat.py"
      },
      %Model{
        id: 6,
        recipient: "LISS panel",
        researcher: nil,
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoe mensen WhatsApp gebruiken. Gegevens, zoals het aantal WhatsApp groepen waar u in zit en het aantal WhatsApp contacten, zullen uit uw WhatsApp account bestand gehaald worden. Dit zijn echter geen gegevens die te herleiden zijn naar personen.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how people use WhatsApp. Information, such as the number of WhatsApp groups you participate in and the number of contacts you interact with, will be extracted from your WhatsApp account information. However, no personal identifiable information will be extracted."
        },
        platform: "WhatsApp",
        redirect_to: :thanks_whatsapp,
        storage: :s3,
        storage_info: %{key: "whatsapp_account_liss"},
        script: "whatsapp_account.py"
      },
      %Model{
        id: 7,
        recipient: "LISS panel",
        researcher: nil,
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoe mensen WhatsApp groepen gebruiken. Gegevens, zoals aantal berichten per persoon, zullen uit uw WhatsApp groep bestand gehaald worden. Dit zijn echter geen gegevens die te herleiden zijn naar personen.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how people use WhatsApp groups. Information, such as number of messages per person, will be extracted from your WhatsApp group data. However, no personal identifiable information will be extracted."
        },
        platform: "WhatsApp",
        redirect_to: nil,
        storage: :centerdata,
        storage_info: %{quest: "L_Datadonation_CHAT"},
        script: "whatsapp_chat.py"
      },
      %Model{
        id: 8,
        recipient: "LISS panel",
        researcher: nil,
        research_topic: nil,
        research_description: %{
          "nl" =>
            "De gegevens die we u vragen te doneren kunnen worden gebruikt om te onderzoeken hoe mensen WhatsApp gebruiken. Gegevens, zoals het aantal WhatsApp groepen waar u in zit en het aantal WhatsApp contacten, zullen uit uw WhatsApp account bestand gehaald worden. Dit zijn echter geen gegevens die te herleiden zijn naar personen.",
          "en" =>
            "The data that we ask you to donate could be used to investigate how people use WhatsApp. Information, such as the number of WhatsApp groups you participate in and the number of contacts you interact with, will be extracted from your WhatsApp account information. However, no personal identifiable information will be extracted."
        },
        platform: "WhatsApp",
        redirect_to: nil,
        storage: :centerdata,
        storage_info: %{quest: "L_Datadonation_ACCOUNT"},
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
