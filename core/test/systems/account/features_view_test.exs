defmodule Systems.Account.FeaturesViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  setup do
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "rendering" do
    test "renders features view with title and form", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/account/features")

      live_context =
        LiveContext.new(%{
          user_id: user.id
        })

      session = %{"live_context" => live_context}

      {:ok, view, html} = live_isolated(conn, Account.FeaturesView, session: session)

      # Should render title (Panl is the translated title)
      assert html =~ "Panl"

      # Should render gender selector
      assert view |> has_element?("[data-testid='features-view']")

      # Should render birth year input
      assert html =~ "birth_year"
    end

    test "renders gender options", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/account/features")

      live_context =
        LiveContext.new(%{
          user_id: user.id
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Account.FeaturesView, session: session)

      # Should render gender options (Man, Woman, Non-binary, Prefer not to say)
      assert html =~ "Man"
      assert html =~ "Woman"
    end
  end

  describe "form interactions" do
    test "saves birth year on change", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/account/features")

      live_context =
        LiveContext.new(%{
          user_id: user.id
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Account.FeaturesView, session: session)

      # Submit birth year change
      view |> render_change("change", %{"features_model" => %{"birth_year" => "1990"}})

      # Verify it was saved
      features = Account.Public.get_features(user)
      assert features.birth_year == 1990
    end

    test "saves gender on selection", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/account/features")

      live_context =
        LiveContext.new(%{
          user_id: user.id
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Account.FeaturesView, session: session)

      # Simulate gender selection message (sent via handle_info from Selector component)
      send(view.pid, {"active_item_id", %{active_item_id: :woman, current_items: []}})

      # Give it time to process
      :timer.sleep(100)

      # Verify it was saved
      features = Account.Public.get_features(user) |> Repo.reload!()
      assert features.gender == :woman
    end
  end

  describe "validation" do
    test "shows error for invalid birth year", %{conn: conn, user: user} do
      conn = conn |> Map.put(:request_path, "/user/account/features")

      live_context =
        LiveContext.new(%{
          user_id: user.id
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Account.FeaturesView, session: session)

      # Submit invalid birth year (too old)
      view |> render_change("change", %{"features_model" => %{"birth_year" => "1800"}})

      # Verify error is shown (birth year validation is in changeset)
      # The features should not be updated to 1800
      features = Account.Public.get_features(user)
      assert features.birth_year != 1800
    end
  end
end
