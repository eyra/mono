defmodule Systems.Advert.AssemblyTest do
  use CoreWeb.ConnCase

  import Mox
  alias Core.Repo
  alias CoreWeb.UI.Timestamp

  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Alliance
  alias Systems.Pool
  alias Systems.Budget

  setup_all do
    Mox.defmock(Systems.Advert.AssemblyTest.UnsplashMockClient,
      for: Core.ImageCatalog.Unsplash.Client
    )

    Application.put_env(:core, :unsplash_client, Advert.AssemblyTest.UnsplashMockClient)
    mock = Advert.AssemblyTest.UnsplashMockClient

    {:ok, mock: mock}
  end

  setup do
    currency = Budget.Factories.create_currency("test_1234", :legal, "ƒ", 2)
    budget = Budget.Factories.create_budget("test_1234", currency)
    pool = Factories.insert!(:pool, %{name: "test_1234", director: :citizen, currency: currency})

    {:ok, currency: currency, budget: budget, pool: pool}
  end

  describe "advert assembly" do
    alias Systems.Advert

    setup [:login_as_researcher]

    test "create questionnaire", %{user: researcher, mock: mock, budget: budget, pool: pool} do
      mock
      |> expect(:get, fn _, "/photos/random", "query=abstract" ->
        {:ok,
         %{
           "urls" => %{"raw" => "http://example.org"},
           "user" => %{"username" => "tester", "name" => "Miss Test"},
           "blur_hash" => "asdf"
         }}
      end)

      advert =
        Advert.Assembly.create(:questionnaire, researcher, "New Advertisement", pool, budget)

      assert %Systems.Advert.Model{
               auth_node: %Core.Authorization.Node{
                 id: advert_auth_node_id,
                 parent_id: nil
               },
               assignment: %Systems.Assignment.Model{
                 info: %Systems.Assignment.InfoModel{
                   subject_count: nil,
                   duration: nil,
                   language: :en,
                   devices: [:phone, :tablet, :desktop],
                   ethical_approval: nil,
                   ethical_code: nil
                 },
                 workflow: %Systems.Workflow.Model{
                   id: workflow_id,
                   auth_node: %Core.Authorization.Node{
                     id: workflow_auth_node_id
                   }
                 },
                 auth_node: %Core.Authorization.Node{
                   id: assignment_auth_node_id
                 },
                 crew: %Systems.Crew.Model{
                   auth_node: %Core.Authorization.Node{
                     parent_id: crew_auth_node_parent_id
                   }
                 }
               },
               promotion: %Systems.Promotion.Model{
                 auth_node: %Core.Authorization.Node{
                   parent_id: promotion_auth_node_parent_id
                 },
                 banner_photo_url: banner_photo_url,
                 banner_subtitle: nil,
                 banner_title: banner_title,
                 banner_url: nil,
                 description: nil,
                 expectations: nil,
                 image_id:
                   "raw_url=http%3A%2F%2Fexample.org&username=tester&name=Miss+Test&blur_hash=asdf",
                 marks: ["vu"],
                 subtitle: nil,
                 director: :advert,
                 themes: nil,
                 title: "New Advertisement"
               }
             } = advert

      assert promotion_auth_node_parent_id == advert_auth_node_id
      assert crew_auth_node_parent_id == assignment_auth_node_id

      assert banner_photo_url == researcher.profile.photo_url
      assert banner_title == researcher.displayname

      # WORKFLOW

      assert %Systems.Workflow.Model{
               type: :many_mandatory,
               items: [
                 %Systems.Workflow.ItemModel{
                   group: nil,
                   position: 0,
                   title: nil,
                   description: nil,
                   tool_ref: %{
                     alliance_tool: %Systems.Alliance.ToolModel{
                       auth_node: %Core.Authorization.Node{
                         parent_id: ^workflow_auth_node_id
                       },
                       url: nil,
                       director: :assignment
                     },
                     feldspar_tool_id: nil,
                     document_tool_id: nil,
                     lab_tool_id: nil
                   }
                 }
               ]
             } = Assignment.Public.get_workflow!(workflow_id, Workflow.Model.preload_graph(:down))

      # ADVERT OWNER

      assert %Systems.Advert.Model{
               auth_node: %Core.Authorization.Node{
                 role_assignments: [
                   %Core.Authorization.RoleAssignment{
                     principal_id: principal_id,
                     role: :owner
                   }
                 ]
               }
             } = Advert.Public.get!(advert.id, auth_node: [:role_assignments])

      assert principal_id === researcher.id
    end

    test "delete", %{user: researcher, mock: mock, budget: budget, pool: pool} do
      mock
      |> expect(:get, fn _, "/photos/random", "query=abstract" ->
        {:ok,
         %{
           "urls" => %{"raw" => "http://example.org"},
           "user" => %{"username" => "tester", "name" => "Miss Test"},
           "blur_hash" => "asdf"
         }}
      end)

      %{id: id} =
        Advert.Assembly.create(:questionnaire, researcher, "New Advertisement", pool, budget)

      advert = Advert.Public.get!(id, Advert.Model.preload_graph(:down))

      Advert.Assembly.delete(advert)

      assert Repo.get(Advert.Model, advert.id) == nil
      assert Repo.get(Core.Authorization.Node, advert.auth_node_id) == nil
      assert Repo.get(Systems.Promotion.Model, advert.promotion_id) == nil
      assert Repo.get(Core.Authorization.Node, advert.promotion.auth_node_id) == nil
      assert Repo.get(Systems.Assignment.Model, advert.assignment_id) != nil
    end

    test "copy", %{user: researcher, mock: mock, budget: budget, pool: pool} do
      mock
      |> expect(:get, fn _, "/photos/random", "query=abstract" ->
        {:ok,
         %{
           "urls" => %{"raw" => "http://example.org"},
           "user" => %{"username" => "tester", "name" => "Miss Test"},
           "blur_hash" => "asdf"
         }}
      end)

      %{id: id} =
        Advert.Assembly.create(:questionnaire, researcher, "New Advertisement", pool, budget)

      %{
        id: id,
        submission:
          %{
            pool: %{name: pool_name},
            criteria: criteria
          } = submission,
        assignment: %{
          info: info,
          crew: crew1,
          workflow: %{
            items: [
              %{
                tool_ref: %Systems.Workflow.ToolRefModel{
                  alliance_tool: tool
                }
              }
            ]
          }
        }
      } =
        Advert.Public.get!(id,
          assignment: Assignment.Model.preload_graph(:down),
          submission: [:pool, :criteria]
        )

      # Update Submission
      reward_value = 1
      status = :submitted
      schedule_start = Timestamp.now() |> Timestamp.format_user_input_date()
      schedule_end = Timestamp.now() |> Timestamp.format_user_input_date()

      {:ok, %{submission: _}} =
        Pool.Public.update(submission, %{
          reward_value: reward_value,
          status: status,
          schedule_start: schedule_start,
          schedule_end: schedule_end
        })

      genders = [:woman]
      dominant_hands = [:left]
      native_languages = [:en, :nl]

      # Update Criteria
      criteria
      |> Pool.CriteriaModel.changeset(%{
        genders: genders,
        dominant_hands: dominant_hands,
        native_languages: native_languages
      })
      |> Repo.update!()

      # Update Tool
      alliance_url = "https://eyra.co/alliances/1"

      tool
      |> Alliance.ToolModel.changeset(:update, %{
        url: alliance_url,
        director: :assignment
      })
      |> Repo.update!()

      # Update Inquiry
      subject_count = 2
      duration = "10"
      language = :en
      ethical_approval = true
      ethical_code = "RERB"
      devices = [:desktop, :tablet]

      info
      |> Assignment.InfoModel.changeset(:update, %{
        subject_count: subject_count,
        duration: duration,
        language: language,
        ethical_approval: ethical_approval,
        ethical_code: ethical_code,
        devices: devices
      })
      |> Repo.update!()

      advert = Advert.Public.get!(id, Advert.Model.preload_graph(:down))

      {:ok, %{advert: %{id: id2}}} = Advert.Assembly.copy(advert)
      advert2 = Advert.Public.get!(id2, Advert.Model.preload_graph(:down))

      assert %{
               auth_node: %{role_assignments: [%{role: :owner}]},
               submission: %{
                 reward_value: nil,
                 schedule_end: ^schedule_end,
                 schedule_start: ^schedule_start,
                 criteria: %{
                   genders: ^genders,
                   dominant_hands: ^dominant_hands,
                   native_languages: ^native_languages
                 },
                 pool: %{
                   name: ^pool_name
                 },
                 status: :idle
               },
               promotion: %{
                 title: "New Advertisement (copy)"
               },
               assignment: %{
                 info: %{
                   subject_count: ^subject_count,
                   duration: ^duration,
                   language: ^language,
                   ethical_approval: ^ethical_approval,
                   ethical_code: ^ethical_code,
                   devices: ^devices
                 },
                 crew: crew2,
                 workflow: %{items: []}
               }
             } = advert2

      assert crew1.id != crew2.id
    end
  end
end
