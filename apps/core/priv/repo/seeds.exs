# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Link.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
#
survey_url = "https://vuamsterdam.eu.qualtrics.com/jfe/form/SV_4Po8iTxbvcxtuaW"

studies = [
  %{
    type: :survey_tool,
    title: "A study about E-numbers, food and beverages",
    survey_url: survey_url,
    description: ~S"""
    With this survey we want to learn more about people's feelings towards the
    addition of additives with "E-numbers" to food and beverages. This study
    contains a short video with sound, so please only participate when you are
    able to listen (using speakers or headphones).
    """,
    published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    desktop_enabled: true,
    phone_enabled: false,
    tablet_enabled: false,
    subject_count: 400,
    duration: "a few minutes",
    reward_currency: :eur,
    reward_value: 2500
  },
  %{
    type: :survey_tool,
    title: "Staying in contact with your parents",
    survey_url: survey_url,
    description: ~S"""
    In this study we want to investigate how people stay in touch with their
    parent(s) after they have moved out of the parental home. It will take
    approximately 20 minutes to complete the questionnaire.
    """,
    published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
    desktop_enabled: true,
    phone_enabled: true,
    tablet_enabled: true,
    subject_count: 56,
    duration: "a while",
    reward_currency: :usd,
    reward_value: 3300
  },
  %{
    type: :client_script,
    title: "Files from ZIP",
    script: """
    import zipfile

    def process(file_data):
        names = []
        data = []
        zfile = zipfile.ZipFile(file_data)
        for name in zfile.namelist():
            names.append(name)
            data.append((name, zfile.read(name).decode("utf8")))

        return {
            "summary": f"The following files where read: {', '.join(names)}.",
            "data": data
        }
    """
  }
]

password = "asdf;lkjASDF0987"

_member =
  Core.Factories.insert!(:member,
    email: "member@eyra.co",
    password: password
  )

researcher =
  Core.Factories.insert!(:researcher,
    email: "researcher@eyra.co",
    password: password
  )

for data <- studies do
  study =
    Core.Factories.insert!(:study, %{
      title: data.title,
      description: ""
    })

  {type, tool_data} = Map.pop!(data, :type)

  Core.Factories.insert!(
    type,
    Map.merge(%{study: study}, tool_data)
  )

  Core.Authorization.assign_role(
    researcher,
    study,
    :owner
  )
end
