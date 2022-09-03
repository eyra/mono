defmodule Systems.Campaign.ViewModelBuilderTest do
  use Core.DataCase

  alias Systems.{
    Assignment,
    Promotion,
    Campaign,
    Crew
  }

  alias Frameworks.Utility.ViewModelBuilder

  describe "Campaign ViewModelBuilder for Assignment.LandingPage" do
    alias Core.Factories

    setup do
      user = Factories.insert!(:member)
      survey_tool = Factories.insert!(:survey_tool, %{survey_url: "https://eyra.co/fake_survey"})
      assignment = Factories.insert!(:assignment, %{survey_tool: survey_tool})

      promotion =
        Factories.insert!(:promotion, %{
          title: "This is a test title",
          expectations: "These are the expectations for the participants"
        })

      submission = Factories.insert!(:submission, %{reward_value: 5})

      %{id: id} =
        Factories.insert!(:campaign, %{
          assignment: assignment,
          promotion: promotion,
          submissions: [submission]
        })

      campaign =
        Campaign.Context.get!(id, Campaign.Model.preload_graph(:full))
        |> Campaign.Context.flatten()

      {:ok, campaign: campaign, user: user}
    end

    test "With applied member", %{campaign: campaign, user: user} do
      member = Crew.Context.apply_member!(campaign.promotable_assignment.crew, user)
      view_model = Campaign.Builders.AssignmentLandingPage.view_model(campaign, user)

      assert %{
               call_to_action: %{
                 label: "Naar vragenlijst",
                 path: "https://eyra.co/fake_survey?panl_id=1",
                 target: %{type: :event, value: "open"}
               },
               hero_title: "Online Studie",
               highlights: [
                 %{text: "5 credits", title: "Beloning"},
                 %{text: "Nog niet gestart", title: "Gestart"},
                 %{text: "Nog niet afgerond", title: "Afgerond"}
               ],
               subtitle: "Je bent aangemeld voor deelname",
               text: "These are the expectations for the participants",
               title: "This is a test title"
             } = view_model
    end

    test "With started member", %{campaign: campaign, user: user} do
      member = Crew.Context.apply_member!(campaign.promotable_assignment.crew, user)
      task = Crew.Context.get_task(campaign.promotable_assignment.crew, member)
      Crew.Context.lock_task(task)

      view_model = Campaign.Builders.AssignmentLandingPage.view_model(campaign, user)

      assert %{
               call_to_action: %{
                 label: "Naar vragenlijst",
                 path: "https://eyra.co/fake_survey?panl_id=1",
                 target: %{type: :event, value: "open"}
               },
               hero_title: "Online Studie",
               highlights: [
                 %{text: "5 credits", title: "Beloning"},
                 %{text: started_at, title: "Gestart"},
                 %{text: "Nog niet afgerond", title: "Afgerond"}
               ],
               subtitle: "Je bent aangemeld voor deelname",
               text: "These are the expectations for the participants",
               title: "This is a test title"
             } = view_model

      assert started_at =~ "vandaag om"
    end

    test "With finished member", %{campaign: campaign, user: user} do
      member = Crew.Context.apply_member!(campaign.promotable_assignment.crew, user)
      task = Crew.Context.get_task(campaign.promotable_assignment.crew, member)
      Crew.Context.lock_task(task)
      Crew.Context.activate_task(task)

      view_model = Campaign.Builders.AssignmentLandingPage.view_model(campaign, user)

      assert %{
               call_to_action: %{
                 label: "Naar vragenlijst",
                 path: "https://eyra.co/fake_survey?panl_id=1",
                 target: %{type: :event, value: "open"}
               },
               hero_title: "Online Studie",
               highlights: [
                 %{text: "5 credits", title: "Beloning"},
                 %{text: started_at, title: "Gestart"},
                 %{text: finished_at, title: "Afgerond"}
               ],
               subtitle: "Je hebt deze vragenlijst ingevuld",
               text: text,
               title: "This is a test title"
             } = view_model

      assert started_at =~ "vandaag om"
      assert finished_at =~ "vandaag om"
      assert text =~ "Jouw bijdrage wordt door de auteur van deze studie beoordeeld."
    end

    test "Without applied member" do
      user = Factories.insert!(:member)
      submission = Factories.insert!(:submission, %{reward_value: 5})

      %{id: id, promotion: promotion} = Factories.insert!(:campaign, %{submissions: [submission]})

      campaign = Campaign.Context.get!(id, Campaign.Model.preload_graph(:full))
      view_model = Campaign.Builders.AssignmentLandingPage.view_model(campaign, user)

      assert %{
               call_to_action: %{
                 label: "Meld je aan",
                 target: %{type: :event, value: "apply"}
               },
               hero_title: "Online Studie",
               highlights: [%{text: "5 credits", title: "Beloning"}],
               subtitle: "subtitle.label",
               text: nil,
               withdraw_redirect: %{
                 label: "Naar de marktplaats",
                 target: %{type: :event, value: "marketplace"}
               }
             } = view_model
    end
  end

  describe "Campaign ViewModelBuilder for Promotion.LandingPage" do
    alias Core.Factories

    setup do
      user = Factories.insert!(:member)

      survey_tool =
        Factories.insert!(
          :survey_tool,
          %{
            survey_url: "https://eyra.co/fake_survey",
            subject_count: 10,
            duration: "10",
            language: "en",
            devices: [:desktop]
          }
        )

      assignment = Factories.insert!(:assignment, %{survey_tool: survey_tool})

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

      submission = Factories.insert!(:submission, %{reward_value: 5})
      author = Factories.build(:author)

      %{id: id} =
        Factories.insert!(:campaign, %{
          assignment: assignment,
          promotion: promotion,
          authors: [author],
          submission: [submission]
        })

      campaign = Campaign.Context.get!(id, Campaign.Model.preload_graph(:full))
      {:ok, campaign: campaign, user: user, author: author}
    end

    test "With 0 applications yet", %{campaign: campaign, user: user, author: author} do
      view_model = Campaign.Builders.PromotionLandingPage.view_model(campaign, user)

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

    test "With 1 application", %{campaign: campaign, user: user} do
      user2 = Factories.insert!(:member)
      member = Crew.Context.apply_member!(campaign.promotable_assignment.crew, user2)
      view_model = Campaign.Builders.PromotionLandingPage.view_model(campaign, user)

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
