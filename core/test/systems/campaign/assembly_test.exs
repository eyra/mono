defmodule Systems.Campaign.AssemblyTest do
  use CoreWeb.ConnCase

  import Mox
  alias Core.Repo
  alias Systems.Campaign

  setup_all do
    Mox.defmock(Systems.Campaign.AssemblyTest.UnsplashMockClient,
      for: Core.ImageCatalog.Unsplash.Client
    )

    Application.put_env(:core, :unsplash_client, Campaign.AssemblyTest.UnsplashMockClient)
    {:ok, mock: Campaign.AssemblyTest.UnsplashMockClient}
  end

  describe "campaign assembly" do
    alias Systems.Campaign

    setup [:login_as_researcher]

    test "create", %{user: researcher, mock: mock} do
      mock
      |> expect(:get, fn _, "/photos/random", "query=abstract" ->
        {:ok,
         %{
           "urls" => %{"raw" => "http://example.org"},
           "user" => %{"username" => "tester", "name" => "Miss Test"},
           "blur_hash" => "asdf"
         }}
      end)

      campaign = Campaign.Assembly.create(researcher, "New Campaign")

      assert %Systems.Campaign.Model{
               auth_node: %Core.Authorization.Node{
                 id: campaign_auth_node_id,
                 parent_id: nil
               },
               promotable_assignment: %Systems.Assignment.Model{
                 assignable_data_donation_tool_id: nil,
                 assignable_lab_tool_id: nil,
                 assignable_survey_tool: %Core.Survey.Tool{
                   auth_node: %Core.Authorization.Node{
                     parent_id: survey_tool_auth_node_parent_id
                   },
                   content_node: %Core.Content.Node{
                     parent_id: nil,
                     ready: false
                   },
                   current_subject_count: nil,
                   devices: [:phone, :tablet, :desktop],
                   duration: nil,
                   ethical_approval: nil,
                   ethical_code: nil,
                   language: nil,
                   subject_count: nil,
                   director: :campaign,
                   survey_url: nil
                 },
                 auth_node: %Core.Authorization.Node{
                   id: assignment_auth_node_id,
                   parent_id: assignment_auth_node_parent_id
                 },
                 crew: %Systems.Crew.Model{
                   auth_node: %Core.Authorization.Node{
                     parent_id: crew_auth_node_parent_id
                   }
                 },
                 director: :campaign
               },
               promotion: %Systems.Promotion.Model{
                 auth_node: %Core.Authorization.Node{
                   parent_id: promotion_auth_node_parent_id
                 },
                 banner_photo_url: banner_photo_url,
                 banner_subtitle: nil,
                 banner_title: banner_title,
                 banner_url: nil,
                 content_node: %Core.Content.Node{
                   parent: %Core.Content.Node{
                     parent_id: nil,
                     ready: false
                   },
                   ready: false
                 },
                 description: nil,
                 expectations: nil,
                 image_id:
                   "raw_url=http%3A%2F%2Fexample.org&username=tester&name=Miss+Test&blur_hash=asdf",
                 marks: ["vu"],
                 subtitle: nil,
                 director: :campaign,
                 themes: nil,
                 title: "New Campaign"
               }
             } = campaign

      assert promotion_auth_node_parent_id == campaign_auth_node_id
      assert assignment_auth_node_parent_id == campaign_auth_node_id
      assert crew_auth_node_parent_id == assignment_auth_node_id
      assert survey_tool_auth_node_parent_id == assignment_auth_node_id

      assert banner_photo_url =~ "http://"
      assert banner_title === researcher.displayname

      # CAMPAIGN AUTHORS

      assert %{
               authors: [
                 %Systems.Campaign.AuthorModel{
                   campaign_id: campaign_id,
                   displayname: displayname,
                   fullname: fullname,
                   user_id: user_id,
                   user: %{
                     coordinator: nil,
                     displayname: og_displayname,
                     profile: %Core.Accounts.Profile{
                       fullname: og_fullname,
                       title: nil
                     },
                     researcher: true,
                     student: nil,
                     visited_pages: nil
                   }
                 }
               ]
             } = Campaign.Context.get!(campaign.id, authors: [user: [:profile]])

      assert campaign_id == campaign.id
      assert displayname == og_displayname
      assert fullname == og_fullname
      assert user_id == researcher.id

      # CAMPAIGN OWNER

      assert %Systems.Campaign.Model{
               auth_node: %Core.Authorization.Node{
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: principal_id,
                     role: :owner
                   }
                 ]
               }
             } = Campaign.Context.get!(campaign.id, auth_node: [:role_assignments])

      assert principal_id === researcher.id
    end

    test "delete", %{user: researcher, mock: mock} do
      mock
      |> expect(:get, fn _, "/photos/random", "query=abstract" ->
        {:ok,
         %{
           "urls" => %{"raw" => "http://example.org"},
           "user" => %{"username" => "tester", "name" => "Miss Test"},
           "blur_hash" => "asdf"
         }}
      end)

      campaign = Campaign.Assembly.create(researcher, "New Campaign")
      Campaign.Assembly.delete(campaign)

      assert Repo.get(Campaign.Model, campaign.id) == nil
      assert Repo.get(Systems.Promotion.Model, campaign.promotion_id) == nil
      assert Repo.get(Core.Content.Node, campaign.promotion.content_node_id) == nil
      assert Repo.get(Core.Authorization.Node, campaign.promotion.auth_node_id) == nil
      assert Repo.get(Systems.Assignment.Model, campaign.promotable_assignment_id) == nil
      assert Repo.get(Core.Authorization.Node, campaign.promotable_assignment.auth_node_id) == nil
      assert Repo.get(Systems.Crew.Model, campaign.promotable_assignment.crew_id) == nil

      assert Repo.get(Core.Authorization.Node, campaign.promotable_assignment.crew.auth_node_id) ==
               nil

      assert Repo.get(Core.Survey.Tool, campaign.promotable_assignment.assignable_survey_tool_id) ==
               nil

      assert Repo.get(
               Core.Authorization.Node,
               campaign.promotable_assignment.assignable_survey_tool.auth_node_id
             ) == nil

      assert Repo.get(
               Core.Content.Node,
               campaign.promotable_assignment.assignable_survey_tool.content_node_id
             ) == nil
    end
  end
end
