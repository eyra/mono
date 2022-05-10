defmodule Systems.DataDonation.ModelData do
  defmodule NoResultsError do
    @moduledoc false
    defexception [:message]
  end

  import CoreWeb.Gettext

  defp data(),
    do: [
      %Systems.DataDonation.Model{
        id: 1,
        researcher: "dr. Bella Struminskaya",
        pronoun: dgettext("eyra-ui", "pronoun.her"),
        research_topic: "Local processing of digital trace data",
        file_type: "Google",
        job_title: "Assistant Professor",
        image: "/images/uu_card.svg",
        institution: "University Utrecht",
        redirect_to: :thanks,
        storage: :s3,
        storage_info: %{},
        script: "script.py"
      },
      %Systems.DataDonation.Model{
        id: 2,
        researcher: "dr. Bella Struminskaya",
        pronoun: dgettext("eyra-ui", "pronoun.her"),
        research_topic: "Local processing of digital trace data",
        file_type: "Google",
        job_title: "Assistant Professor",
        image: "/images/uu_card.svg",
        institution: "University Utrecht",
        redirect_to: nil,
        storage: :centerdata,
        storage_info: %{quest: "test_arnaud"},
        script: "zip_contents.py"
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
