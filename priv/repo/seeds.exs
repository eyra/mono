# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Link.Repo.insert!(%Link.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
#
survey_url = "https://vuamsterdam.eu.qualtrics.com/jfe/form/SV_4Po8iTxbvcxtuaW"

studies = [
  %{
    title: "A study about E-numbers, food and beverages",
    description: ~S"""
    With this survey we want to learn more about people's feelings towards the
    addition of additives with "E-numbers" to food and beverages. This study
    contains a short video with sound, so please only participate when you are
    able to listen (using speakers or headphones).
    """,
    phone_enabled: false,
    tablet_enabled: false,
    subject_count: 400,
    study_duration: 16,
    fee: "2.5"
  },
  %{
    title: "Staying in contact with your parents",
    description: ~S"""
    In this study we want to investigate how people stay in touch with their
    parent(s) after they have moved out of the parental home. It will take
    approximately 20 minutes to complete the questionnaire.
    """,
    subject_count: 56,
    study_duration: 20,
    fee: "3,3"
  }
]

password_hash = Pow.Ecto.Schema.Password.pbkdf2_hash("asdf;lkj")

_member =
  Link.Factories.insert!(:member, %{
    email: "member@eyra.co",
    password_hash: password_hash
  })

researcher =
  Link.Factories.insert!(:researcher, %{
    email: "researcher@eyra.co",
    password_hash: password_hash
  })

for data <- studies do
  study =
    Link.Factories.insert!(:study, %{
      title: data.title,
      description: ""
    })

  _survey_tool =
    Link.Factories.insert!(:survey_tool, %{
      study: study,
      survey_url: survey_url,
      description: data.description,
      subject_count: data.subject_count,
      phone_enabled: Map.get(data, :phone_enabled, true),
      tablet_enabled: Map.get(data, :tablet_enabled, true),
      desktop_enabled: Map.get(data, :desktop_enabled, true)
    })

  Link.Authorization.assign_role(
    Link.Authorization.principal(researcher).id,
    study.auth_node_id,
    :owner
  )
end
