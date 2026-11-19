defmodule Next.Systems.BFF.PageControllerTest do
  # Not async: the flags-off test changes the app's feature flags.
  use NextWeb.ConnCase
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
  defp create_panl_advert(panl, opts \\ []) do
    advert = Advert.Factories.create_advert(Factories.insert!(:creator), :accepted, 1)
    {:ok, advert} = advert |> Ecto.Changeset.change(status: :online) |> Repo.update()

    {:ok, _} =
      advert.submission
      |> Ecto.Changeset.change(
        reward_value: 0,
        pool_id: panl.id,
        submitted_at: opts[:submitted_at]
      )
      |> Repo.update()

    if title = opts[:title] do
      %{promotion: promotion} = Repo.preload(advert, :promotion)
      promotion |> Ecto.Changeset.change(title: title) |> Repo.update!()
    end

    advert
  end

  defp create_untitled_panl_advert(panl) do
    %{promotion: promotion} = advert = create_panl_advert(panl)
    {:ok, _} = promotion |> Ecto.Changeset.change(title: nil) |> Repo.update()
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
      {_panl, %Assignment.Model{id: assignment_id}} = home_with_everything(user)

      page = conn |> get("/bff/page/home") |> json_response(200)

      assert types(page) == [
               "next_best_action",
               "section",
               "reward_amount",
               "reward_amount",
               "reward_amount",
               "section",
               "advert",
               "section",
               "section",
               "participation"
             ]

      %{"blocks" => blocks, "markup" => markup} = page
      participation_id = "participation/assignment/#{assignment_id}"

      assert [
               "next-best-action",
               "rewards",
               "rewards-pending",
               "rewards-approved",
               "rewards-rejected",
               "marketplace",
               "advert/promotion/" <> _,
               "marketplace-see-all",
               "history",
               ^participation_id
             ] = Enum.map(blocks, & &1["id"])

      # As on the web home, the rewards, the marketplace and the history each sit in a box.
      assert markup == [
               %{
                 "kind" => "border",
                 "start" => "rewards",
                 "end" => "rewards-rejected",
                 "props" => %{}
               },
               %{
                 "kind" => "border",
                 "start" => "marketplace",
                 "end" => "marketplace-see-all",
                 "props" => %{}
               },
               %{
                 "kind" => "border",
                 "start" => "history",
                 "end" => participation_id,
                 "props" => %{}
               }
             ]

      assert [
               %{
                 "props" => %{
                   "title" => "first",
                   "body" => "About first",
                   "cta" => "Open first",
                   "to" => "/todo/first"
                 }
               },
               %{"props" => %{"title" => "Rewards"}},
               %{"props" => %{"label" => "Awaiting", "tone" => "warning", "amount" => pending}},
               %{
                 "props" => %{"label" => "Approved", "tone" => "success", "amount" => approved}
               },
               %{"props" => %{"label" => "Rejected", "tone" => "danger", "amount" => rejected}},
               %{
                 "props" => %{
                   "title" => "Marketplace",
                   "count" => 1,
                   "image_url" => "/images/logos/pools/panl_wide.png"
                 }
               },
               %{"props" => %{"to" => "/promotion/" <> _, "info" => "Duration: " <> _}},
               %{"props" => %{"title" => "See all", "to" => "/bff/page/marketplace"}},
               %{"props" => %{"title" => "History", "count" => 1}},
               %{"props" => %{"reward" => "Reward: " <> _, "to" => participation_to}}
             ] = blocks

      assert {pending, approved, rejected} == {"€2.50", "€12.00", "€3.00"}
      assert participation_to == "/assignment/#{assignment_id}"
    end

    test "home shows three studies of the marketplace and of the history and links to pages with all of them",
         %{conn: conn, user: user} do
      {panl, _assignment} = home_with_everything(user)

      for _ <- 1..3 do
        create_panl_advert(panl)
        Assignment.Public.add_participant!(Assignment.Factories.create_assignment(31, 1), user)
      end

      home = conn |> get("/bff/page/home") |> json_response(200)

      assert Enum.frequencies(types(home)) |> Map.take(["advert", "participation"]) ==
               %{"advert" => 3, "participation" => 3}

      assert [
               %{"title" => "Rewards"},
               %{"title" => "Marketplace", "count" => 4},
               %{"title" => "See all", "to" => "/bff/page/marketplace"},
               %{"title" => "History", "count" => 4},
               %{"title" => "See all", "to" => "/bff/page/history"}
             ] = for(%{"type" => "section", "props" => props} <- home["blocks"], do: props)

      assert types(conn |> get("/bff/page/marketplace") |> json_response(200)) ==
               ["section", "filter", "search" | List.duplicate("advert", 4)]

      assert types(conn |> get("/bff/page/history") |> json_response(200)) ==
               ["section" | List.duplicate("participation", 4)]
    end

    test "the marketplace filters on the year a study was published and searches its title, as on the web, through links to itself",
         %{conn: conn, user: user} do
      {panl, _assignment} = home_with_everything(user)
      create_panl_advert(panl, title: "Sleep and screens", submitted_at: ~N[2024-06-15 12:00:00])
      create_panl_advert(panl, title: "Screens at night", submitted_at: ~N[2025-03-01 09:00:00])
      this_year = "#{NaiveDateTime.utc_now().year}"
      page = "/bff/page/marketplace"

      marketplace = fn query ->
        %{"blocks" => blocks} = conn |> get(page <> query) |> json_response(200)
        blocks
      end

      assert [
               %{"props" => %{"title" => "Marketplace", "count" => 3}},
               %{"type" => "filter", "props" => %{"label" => "Filter:", "options" => options}},
               %{"type" => "search", "props" => search} | adverts
             ] = marketplace.("")

      assert options == [
               %{"label" => "All", "to" => page, "selected" => true},
               %{"label" => this_year, "to" => "#{page}?year=#{this_year}", "selected" => false},
               %{"label" => "2025", "to" => "#{page}?year=2025", "selected" => false},
               %{"label" => "2024", "to" => "#{page}?year=2024", "selected" => false}
             ]

      assert search == %{"name" => "query", "to" => page, "placeholder" => "Search"}
      assert length(adverts) == 3

      # Each link keeps the other param: a year keeps the search, the search keeps the year.
      assert [
               %{"props" => %{"count" => 1}},
               %{"props" => %{"options" => [all | _] = options}},
               %{"props" => search},
               %{"type" => "advert", "props" => %{"title" => "Screens at night"}}
             ] = marketplace.("?year=2025&query=+screens+")

      assert all == %{"label" => "All", "to" => "#{page}?query=screens", "selected" => false}

      assert %{"label" => "2025", "to" => "#{page}?query=screens&year=2025", "selected" => true} in options

      assert search == %{
               "name" => "query",
               "to" => "#{page}?year=2025",
               "placeholder" => "Search",
               "value" => "screens"
             }

      assert [%{"props" => %{"count" => 0}}, _filter, _search, no_studies] =
               marketplace.("?year=2025&query=sleep")

      assert no_studies == %{
               "id" => "marketplace-none",
               "type" => "section",
               "props" => %{"body" => "No studies found."}
             }

      # A year the marketplace doesn't have, or one that isn't a year, counts as All.
      for query <- ["?year=1999", "?year=next", "?year=&query="] do
        assert [%{"props" => %{"count" => 3}} | _] = marketplace.(query)
      end

      # The search text is encoded in the links.
      assert [_heading, %{"props" => %{"options" => [all | _]}} | _] =
               marketplace.("?query=c%2B%2B+%26+more")

      assert all["to"] == "#{page}?query=c%2B%2B%20%26%20more"
    end

    test "an advert without a title shows with an empty title on home and the marketplace page",
         %{conn: conn, user: user} do
      {panl, _assignment} = home_with_everything(user)
      for _ <- 1..3, do: create_untitled_panl_advert(panl)

      home = conn |> get("/bff/page/home") |> json_response(200)
      marketplace = conn |> get("/bff/page/marketplace") |> json_response(200)

      titles = fn %{"blocks" => blocks} ->
        for %{"type" => "advert", "props" => %{"title" => title}} <- blocks, do: title
      end

      # The app drops an advert block without a title, so the heading's count would lie.
      assert [%{"type" => "section", "props" => %{"count" => 4}} | _] = marketplace["blocks"]
      assert length(titles.(marketplace)) == 4
      assert Enum.filter(titles.(marketplace), &(&1 in [nil, ""])) == ["", "", ""]

      assert length(titles.(home)) == 3
      assert Enum.reject(titles.(home), &is_binary/1) == []
    end

    # Opening a study's content page makes its participant a tester too: two role rows.
    test "a study the user takes part in and tests shows once on home and the history",
         %{conn: conn, user: user} do
      {_panl, assignment} = home_with_everything(user)
      Assignment.Public.ensure_tester(assignment, user)

      for page <- ["home", "history"] do
        participations =
          conn
          |> get("/bff/page/#{page}")
          |> json_response(200)
          |> types()
          |> Enum.count(&(&1 == "participation"))

        assert participations == 1, page
      end
    end

    test "without panl_post_launch home shows only the next action, history and marketplace nothing",
         %{conn: conn, user: user} do
      home_with_everything(user)
      set_feature_flag(:panl_post_launch, false)

      assert %{"blocks" => [%{"type" => "next_best_action", "props" => %{"title" => "first"}}]} =
               conn |> get("/bff/page/home") |> json_response(200)

      for page <- ["history", "marketplace"] do
        assert %{"blocks" => [], "markup" => []} =
                 conn |> get("/bff/page/#{page}") |> json_response(200)
      end
    end

    test "home leaves out what the user doesn't have", %{conn: conn} do
      assert %{"blocks" => [], "markup" => []} =
               conn |> get("/bff/page/home") |> json_response(200)
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
