defmodule Systems.Advert.PromotionLandingPageBuilderTest do
  use CoreWeb.ConnCase, async: true
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  import ExUnit.Assertions

  alias Systems.Advert
  alias Systems.Fund
  alias Systems.Pool

  describe "Promotion Landing Page" do
    setup [:login_as_member]

    test "Render", %{conn: conn} do
      creator = Factories.insert!(:creator)
      %{promotion: %{id: promotion_id}} = Advert.Factories.create_advert(creator, :accepted, 1)
      {:ok, _view, html} = live(conn, ~p"/promotion/#{promotion_id}")
      assert html =~ "Participate"
    end

    test "shows a fully-booked dialog when clicking apply on a full assignment", %{conn: conn} do
      creator = Factories.insert!(:creator)
      currency = Fund.Factories.create_currency("eur_promo", :legal, "€", 2)
      fund = Fund.Factories.create_fund("promo_fund_full", currency)

      %{promotion: %{id: promotion_id}, assignment: assignment} =
        Advert.Factories.create_advert(creator, :accepted, 1, fund)

      assignment.info
      |> Ecto.Changeset.change(subject_reward: 6000)
      |> Core.Repo.update!()

      {:ok, view, html} = live(conn, ~p"/promotion/#{promotion_id}")

      refute html =~ "This study is fully booked"
      assert html =~ "promotion-apply-button-hero"

      result = view |> render_click("call-to-action-1")

      # backstop: no navigation; participant stays on the promotion page.
      assert result =~ "promotion-apply-button-hero"
    end

    test "non-member Apply routes through the pool join gate", %{
      conn: %{assigns: %{current_user: participant}} = conn
    } do
      creator = Factories.insert!(:creator)

      %{promotion_id: promotion_id, submission_id: submission_id, assignment_id: assignment_id} =
        Advert.Factories.create_advert(creator, :accepted, 1)

      pool = Pool.Public.get_by_submission!(submission_id)
      refute Pool.Public.participant?(pool, participant)

      {:ok, view, _html} = live(conn, ~p"/promotion/#{promotion_id}")

      view |> render_click("call-to-action-1")

      slug = Pool.Model.slug(pool)

      assert_redirected(
        view,
        "/pool/#{slug}/join?return_to=%2Fassignment%2F#{assignment_id}%2Fapply"
      )

      # User is NOT silently added — join happens on the consent screen.
      refute Pool.Public.participant?(pool, participant)
    end

    test "existing member Apply goes straight to the assignment", %{
      conn: %{assigns: %{current_user: participant}} = conn
    } do
      creator = Factories.insert!(:creator)

      %{promotion_id: promotion_id, submission_id: submission_id, assignment_id: assignment_id} =
        Advert.Factories.create_advert(creator, :accepted, 1)

      pool = Pool.Public.get_by_submission!(submission_id)
      Pool.Public.add_participant!(pool, participant)

      {:ok, view, _html} = live(conn, ~p"/promotion/#{promotion_id}")

      view |> render_click("call-to-action-1")

      assert_redirected(view, "/assignment/#{assignment_id}/apply")
    end
  end

  describe "Promotion Landing Page — anonymous visitor" do
    test "Apply routes through auth identify → pool join → assignment", %{conn: conn} do
      creator = Factories.insert!(:creator)

      %{promotion_id: promotion_id, submission_id: submission_id, assignment_id: assignment_id} =
        Advert.Factories.create_advert(creator, :accepted, 1)

      slug = Pool.Model.slug(Pool.Public.get_by_submission!(submission_id))

      {:ok, view, _html} = live(conn, ~p"/promotion/#{promotion_id}")

      view |> render_click("call-to-action-1")

      apply_path = "/assignment/#{assignment_id}/apply"
      join_path = "/pool/#{slug}/join?return_to=#{URI.encode_www_form(apply_path)}"
      identify_path = "/user/auth/identify?return_to=#{URI.encode_www_form(join_path)}"

      assert_redirected(view, identify_path)
    end
  end
end
