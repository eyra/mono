defmodule Systems.Home.StudiesPageBuilderTest do
  use Core.DataCase

  alias Systems.Home
  alias Systems.Pool
  alias Systems.Advert

  alias Core.Factories

  defp make_panl_participant(user) do
    panl_pool =
      Pool.Public.get_panl() || Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Pool.Public.add_participant!(panl_pool, user)
  end

  # Builds an advert that passes Advert.Public.validate_open/2 for any panl
  # member: online status, an open spot, and reward_value 0 (which short-circuits
  # the funding check, so we don't need to wire up a Fund + currency).
  defp create_open_online_advert(creator, opts \\ []) do
    subject_count = Keyword.get(opts, :subject_count, 1)
    submitted_at = Keyword.get(opts, :submitted_at)

    advert = Advert.Factories.create_advert(creator, :accepted, subject_count)

    {:ok, advert} =
      advert |> Ecto.Changeset.change(status: :online) |> Repo.update()

    {:ok, _submission} =
      advert.submission
      |> Ecto.Changeset.change(%{reward_value: 0, submitted_at: submitted_at})
      |> Repo.update()

    advert
  end

  defp creator, do: Factories.insert!(:creator)

  defp panl_member do
    user = Factories.insert!(:member, %{creator: false})
    make_panl_participant(user)
    user
  end

  defp build_assigns(user), do: %{current_user: user, uri_path: "/studies"}

  describe "view_model/2" do
    test "returns Overview > Studies breadcrumbs for guests" do
      vm = Home.StudiesPageBuilder.view_model(nil, %{current_user: nil})

      assert [
               %{label: "Overview", path: "/"},
               %{label: "Studies", path: "/studies"}
             ] = vm.breadcrumbs
    end

    test "guest sees no studies" do
      vm = Home.StudiesPageBuilder.view_model(nil, %{current_user: nil})

      assert vm.items == []
      assert vm.years == []
    end

    test "uses the landing_page hero titled Studies" do
      vm = Home.StudiesPageBuilder.view_model(nil, %{current_user: nil})

      assert %{type: :landing_page, params: %{title: "Studies"}} = vm.hero
    end

    test "panl member without available adverts sees empty items and years" do
      user = Factories.insert!(:member, %{creator: false})
      make_panl_participant(user)

      vm = Home.StudiesPageBuilder.view_model(nil, %{current_user: user, uri_path: "/studies"})

      assert vm.items == []
      assert vm.years == []
    end

    test "panl member sees eligible online adverts as items" do
      researcher = creator()
      user = panl_member()
      create_open_online_advert(researcher)

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert [%{card: %{type: :primary}}] = vm.items
    end

    test "items expose the published year, sourced from submission.submitted_at" do
      researcher = creator()
      user = panl_member()
      create_open_online_advert(researcher, submitted_at: ~N[2024-06-15 12:00:00])
      create_open_online_advert(researcher, submitted_at: ~N[2025-03-01 09:00:00])

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert Enum.map(vm.items, & &1.year) |> Enum.sort() == [2024, 2025]
    end

    test "years are deduplicated when multiple adverts share a year" do
      researcher = creator()
      user = panl_member()
      create_open_online_advert(researcher, submitted_at: ~N[2024-06-15 12:00:00])
      create_open_online_advert(researcher, submitted_at: ~N[2024-09-01 12:00:00])

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert vm.years == [2024]
    end

    test "years are sorted in descending order" do
      researcher = creator()
      user = panl_member()
      create_open_online_advert(researcher, submitted_at: ~N[2024-06-15 12:00:00])
      create_open_online_advert(researcher, submitted_at: ~N[2025-03-01 09:00:00])

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert vm.years == [2025, 2024]
    end

    test "non-online adverts are excluded" do
      researcher = creator()
      user = panl_member()
      # Online + visible
      create_open_online_advert(researcher, submitted_at: ~N[2025-01-01 00:00:00])
      # Default :concept status — should not appear
      Advert.Factories.create_advert(researcher, :accepted, 1)

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert length(vm.items) == 1
    end

    test "adverts that fail validate_open (no open spots) are excluded" do
      researcher = creator()
      user = panl_member()
      create_open_online_advert(researcher, subject_count: 0)

      vm = Home.StudiesPageBuilder.view_model(nil, build_assigns(user))

      assert vm.items == []
      assert vm.years == []
    end
  end
end
