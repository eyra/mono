defmodule Systems.Advert.ViewModelBuilderTest do
  use Core.DataCase

  alias Systems.Assignment
  alias Systems.Promotion
  alias Systems.Advert
  alias Systems.Crew

  alias Frameworks.Utility.ViewModelBuilder

  describe "Advert ViewModelBuilder for Promotion.LandingPage" do
    alias Core.Factories

    setup do
      user = Factories.insert!(:member)

      alliance_tool =
        Factories.insert!(
          :alliance_tool,
          %{
            url: "https://eyra.co/fake_alliance",
            subject_count: 10,
            duration: "10",
            language: "en",
            devices: [:desktop]
          }
        )

      assignment = Factories.insert!(:assignment, %{alliance_tool: alliance_tool})

      promotion =
        Factories.insert!(
          :promotion,
          %{
            title: "This is a test title",
            themes: ["marketing", "econometrics"],
            expectations: "These are the expectations for the participants",
            banner_title: "Banner Title",
            banner_subtitle: "Banner Subtitle",
            banner_photo_url: "https://eyra.co/image/1",
            banner_url: "https://eyra.co/member/1",
            marks: ["vu"]
          }
        )

      submission = Factories.insert!(:pool_submission, %{reward_value: 5})

      %{id: id} =
        Factories.insert!(:advert, %{
          assignment: assignment,
          promotion: promotion,
          submission: submission
        })

      advert = Advert.Public.get!(id, Advert.Model.preload_graph(:down))
      {:ok, advert: advert, user: user, author: author}
    end

    test "With 0 applications yet", %{advert: advert, user: user, author: author} do
      view_model = Advert.PromotionLandingPageBuilder.view_model(advert, user)

      assert %{
               banner_photo_url: "https://eyra.co/image/1",
               banner_subtitle: "Banner Subtitle",
               banner_title: "Banner Title",
               banner_url: "https://eyra.co/member/1",
               call_to_action: %{
                 label: "Meld je aan",
                 target: %{type: :event, value: "apply"}
               },
               description: nil,
               devices: [:desktop],
               byline: byline,
               expectations: "These are the expectations for the participants",
               highlights: [
                 %{text: "5 credits", title: "Beloning"},
                 %{text: "10 minuten", title: "Duur"},
                 %{text: "Nog 10 van de 10", title: "Beschikbare plekken"}
               ],
               image_id: nil,
               languages: ["en"],
               organisation: %Core.Marks.Mark{
                 id: "vu",
                 label: "Vrije Universiteit Amsterdam"
               },
               subtitle: "Kun je in een zin uitleggen waar je studie over gaat?",
               themes: "Marketing, Econometrie",
               title: "This is a test title"
             } = view_model

      assert byline =~ "Door: #{author.fullname}"
    end

    test "With 1 application", %{advert: advert, user: user} do
      user2 = Factories.insert!(:member)

      {:ok, %{member: member}} =
        Crew.Public.apply_member(advert.assignment.crew, user2, ["task2"])

      view_model = Advert.PromotionLandingPageBuilder.view_model(advert, user)

      assert %{
               highlights: [
                 %{text: "5 credits", title: "Beloning"},
                 %{text: "10 minuten", title: "Duur"},
                 %{text: "Nog 9 van de 10", title: "Beschikbare plekken"}
               ]
             } = view_model
    end
  end
end
