defmodule Systems.BFF.PageControllerTest do
  # Not async: the flags-off test changes the app's feature flags.
  use MicaWeb.ConnCase
  use Mica.FeatureFlags.Test

  alias Mica.Factories
  alias Mica.Repo
  alias Systems.Advert
  alias Systems.Assignment
  alias Systems.Fund
  alias Systems.NextAction
  alias Systems.Pool

  defmodule TodoAction do
    @behaviour Systems.NextAction.ViewModel

    @impl true
    def to_view_model(_count, %{"title" => title}) do
      %{
        title: title,
        description: "About #{title}",
        cta_label: "Open #{title}",
        cta_action: %{type: :redirect, to: "/todo/#{title}"}
      }
    end
  end

  defp create_todo(user, title, opts \\ []) do
    NextAction.Public.create_next_action(
      user,
      TodoAction,
      Keyword.merge([key: title, params: %{"title" => title}], opts)
    )
  end

  defp give_reward(user, fund, status, amount) do
    Factories.insert!(:reward, %{
      user: user,
      fund: fund,
      amount: amount,
      status: status,
      idempotence_key: "test=#{System.unique_integer([:positive])}"
    })
  end

  # An online advert in Panl that is open to the user; reward_value 0 skips the funding check.
  defp create_panl_advert(panl) do
    advert = Advert.Factories.create_advert(Factories.insert!(:creator), :accepted, 1)
    {:ok, advert} = advert |> Ecto.Changeset.change(status: :online) |> Repo.update()

    {:ok, _} =
      advert.submission
      |> Ecto.Changeset.change(reward_value: 0, pool_id: panl.id)
      |> Repo.update()

    advert
  end

  defp home_with_everything(user) do
    create_todo(user, "later")
    create_todo(user, "first", priority: :high)
    euro = Fund.Factories.create_currency("euro", :legal, "€", 2)
    fund = Fund.Factories.create_fund("euro-fund", euro)

    for {status, cents} <- [pending_approval: 250, approved: 1200, rejected: 300],
        do: give_reward(user, fund, status, cents)

    panl = Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})
    Pool.Public.add_participant!(panl, user)
    create_panl_advert(panl)

    assignment = Assignment.Factories.create_assignment(31, 1)
    Assignment.Public.add_participant!(assignment, user)

    {panl, assignment}
  end

  defp types(%{"blocks" => blocks}), do: Enum.map(blocks, & &1["type"])

  describe "signed in" do
    setup :login_as_member

    test "home shows what the web home shows: next action, rewards, marketplace, history",
         %{conn: conn, user: user} do
      {%Pool.Model{id: panl_id}, %Assignment.Model{id: assignment_id}} =
        home_with_everything(user)

      page = conn |> get("/bff/page/home") |> json_response(200)

      assert types(page) == [
               "next_best_action",
               "rewards",
               "section",
               "advert",
               "section",
               "section",
               "participation"
             ]

      assert %{
               "blocks" => [
                 %{
                   "props" => %{
                     "title" => "first",
                     "body" => "About first",
                     "cta" => "Open first",
                     "to" => "/todo/first"
                   }
                 },
                 %{
                   "props" => %{
                     "title" => "Rewards",
                     "pending_label" => "Awaiting",
                     "pending_amount" => pending,
                     "approved_label" => "Approved",
                     "approved_amount" => approved,
                     "rejected_label" => "Rejected",
                     "rejected_amount" => rejected,
                     "notes" => []
                   }
                 },
                 %{
                   "props" => %{
                     "title" => "Marketplace",
                     "count" => 1,
                     "image_url" => "/images/logos/pools/panl_wide.png"
                   }
                 },
                 %{"props" => %{"to" => "/promotion/" <> _, "info" => "Duration: " <> _}},
                 %{"props" => %{"title" => "See all", "to" => see_all}},
                 %{"props" => %{"title" => "History", "count" => 1}},
                 %{"props" => %{"reward" => "Reward: " <> _, "to" => participation_to}}
               ]
             } = page

      assert {pending, approved, rejected} == {"€2.50", "€12.00", "€3.00"}
      assert see_all == "/pool/#{panl_id}/marketplace"
      assert participation_to == "/assignment/#{assignment_id}"
    end

    test "without panl_post_launch home shows only the next action", %{conn: conn, user: user} do
      home_with_everything(user)
      set_feature_flag(:panl_post_launch, false)

      assert %{"blocks" => [%{"type" => "next_best_action", "props" => %{"title" => "first"}}]} =
               conn |> get("/bff/page/home") |> json_response(200)
    end

    test "home leaves out what the user doesn't have", %{conn: conn} do
      assert %{"blocks" => []} = conn |> get("/bff/page/home") |> json_response(200)
    end

    test "a page the spec doesn't list is not found", %{conn: conn} do
      assert %{"error" => "Not found"} = conn |> get("/bff/page/settings") |> json_response(404)
    end
  end

  test "signed out gets 401, before the page is looked up", %{conn: conn} do
    for page <- ["home", "settings"] do
      assert %{"error" => "Not authenticated"} =
               conn |> get("/bff/page/#{page}") |> json_response(401)
    end
  end

  test "the SaaS serves exactly the spec's pages" do
    assert Mica.SaaS.bff_pages() |> Map.keys() |> Enum.sort() ==
             Systems.BFF.Blocks.pages() |> Enum.map(& &1.name) |> Enum.sort()
  end
end
