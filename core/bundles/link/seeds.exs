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

images = [
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1498462440456-0dba182e775b%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw5fHx3YXRlcnxlbnwwfHx8fDE2MjE3NzY0MjA%26ixlib%3Drb-1.2.1&username=samaradoole&name=Samara+Doole&blur_hash=LtI~0%3Ft7aeof~qofazayt6f6j%5Bf6",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1552571219-d6e38a3f4849%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw0NXx8ZmlyZXxlbnwwfHx8fDE2MjE3NzY1Mjg%26ixlib%3Drb-1.2.1&username=benjamin_deyoung&name=Benjamin+DeYoung&blur_hash=LlGbI~bcR%2Aoe.Ts.WAj%5B0%2AsmnhWD",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1505009258427-29298f4dc5f6%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw2fHxpY2V8ZW58MHx8fHwxNjIxNzc2NTc2%26ixlib%3Drb-1.2.1&username=scottrodgerson&name=Scott+Rodgerson&blur_hash=LK8%3D%3F9tSf%2CadyZogadkDRjogkCWBraw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1505009258427-29298f4dc5f6%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw2fHxpY2V8ZW58MHx8fHwxNjIxNzc2NTc2%26ixlib%3Drb-1.2.1&username=scottrodgerson&name=Scott+Rodgerson&blur_hash=LK8%3D%3F9tSf%2CadyZogadkDRjogkCWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1429552077091-836152271555%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHwxfHxsaWdodG5pbmd8ZW58MHx8fHwxNjIxNzc2NjMx%26ixlib%3Drb-1.2.1&username=littleppl85&name=Brandon+Morgan&blur_hash=LX9k8Z-%3FRhMxtSt8t8ozDgIUo%23xu",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1541534741688-6078c6bfb5c5%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHwxNXx8c3BvcnR8ZW58MHx8fHwxNjIxNzc2NzMw%26ixlib%3Drb-1.2.1&username=johnarano&name=John+Arano&blur_hash=LDAAXTof0LRPWBfQ%252WC4%3Aj%5D%3FGj%5B",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1500468756762-a401b6f17b46%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHwxM3x8c3BvcnR8ZW58MHx8fHwxNjIxNzc2NzMw%26ixlib%3Drb-1.2.1&username=cliqueimages&name=Clique+Images&blur_hash=LoM7lpfQxvoM_Nj%5Bt8f7%25Nj%5BWCWB",
  "raw_url=https%3A%2F%2Fimages.unsplash.com%2Fphoto-1515378791036-0648a3ef77b2%3Fixid%3DMnwyMTY0MzZ8MHwxfHNlYXJjaHw4fHx3b3JrfGVufDB8fHx8MTYyMTc3NjgwOQ%26ixlib%3Drb-1.2.1&username=christinhumephoto&name=Christin+Hume&blur_hash=LMF%3B%3Dw0LAJR%25~A9uT0nNRjxaW%3DIo"
]

studies =
  [
    %{
      type: :survey_tool,
      promotion: %{
        title: "A study about E-numbers, food and beverages",
        subtitle: Faker.Lorem.sentence(),
        description: ~S"""
        With this survey we want to learn more about people's feelings towards the
        addition of additives with "E-numbers" to food and beverages. This study
        contains a short video with sound, so please only participate when you are
        able to listen (using speakers or headphones).
        """,
        published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      survey_tool: %{
        survey_url: survey_url,
        # desktop_enabled: true,
        # phone_enabled: false,
        # tablet_enabled: false,
        subject_count: 400,
        duration: "a few minutes",
        reward_currency: :eur,
        reward_value: 2500
      }
    },
    %{
      type: :survey_tool,
      promotion: %{
        title: "Staying in contact with your parents",
        subtitle: Faker.Lorem.sentence(),
        description: ~S"""
        In this study we want to investigate how people stay in touch with their
        parent(s) after they have moved out of the parental home. It will take
        approximately 20 minutes to complete the questionnaire.
        """,
        published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      },
      survey_tool: %{
        survey_url: survey_url,
        subject_count: 56,
        duration: "a while",
        reward_currency: :usd,
        reward_value: 3300
      }
    }
  ] ++
    Enum.map(images, fn image ->
      %{
        type: :survey_tool,
        promotion: %{
          title: Faker.Lorem.sentence(),
          subtitle: Faker.Lorem.sentence(),
          description: Faker.Lorem.paragraph(),
          image_id: image,
          published_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        },
        survey_tool: %{
          survey_url: Faker.Internet.url(),
          # desktop_enabled: true,
          # phone_enabled: true,
          # tablet_enabled: true,
          subject_count: 56,
          duration: "a while",
          reward_currency: :usd,
          reward_value: 3300
        }
      }
    end)

password = "asdf;lkjASDF0987"

_member =
  Core.Factories.insert!(:member, %{
    email: "member@eyra.co",
    password: password
  })

researcher =
  Core.Factories.insert!(:member, %{
    researcher: true,
    email: "researcher@eyra.co",
    password: password
  })

students =
  for _ <- 1..1500 do
    Core.Factories.insert!(:member)
  end

for study_data <- studies do
  study =
    Core.Factories.insert!(:study, %{
      title: study_data.promotion.title,
      description: ""
    })

  tool_content_node = Core.Factories.insert!(:content_node)
  {tool_type, study_data} = Map.pop!(study_data, :type)
  {tool_data, study_data} = Map.pop!(study_data, tool_type)
  {promotion_data, study_data} = Map.pop!(study_data, :promotion)

  promotion =
    Core.Factories.insert!(
      :promotion,
      Map.merge(%{parent_content_node: tool_content_node, study: study}, promotion_data)
    )

  tool =
    Core.Factories.insert!(
      tool_type,
      Map.merge(%{content_node: tool_content_node, study: study, promotion: promotion}, tool_data)
    )

  participant_count = :random.uniform(tool.subject_count)

  for student <- Enum.take_random(students, participant_count) do
    Core.Survey.Tools.apply_participant(tool, student)
  end

  Core.Authorization.assign_role(
    researcher,
    study,
    :owner
  )
end
