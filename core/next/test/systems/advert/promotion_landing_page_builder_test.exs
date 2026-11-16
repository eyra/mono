defmodule Next.Systems.Advert.PromotionLandingPageBuilderTest do
  # Next's pool logos (`config :mica, :pixel, pool_assets:`) on Mica's promotion
  # landing page.
  use NextWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Systems.Advert
  alias Systems.Pool

  defp promote_pool_to_panl!(pool) do
    pool
    |> Ecto.Changeset.change(name: "Panl")
    |> Mica.Repo.update!()
  end

  describe "Promotion Landing Page" do
    setup [:login_as_member]

    test "uses the on-dark Panl wordmark for the banner icon", %{conn: conn} do
      creator = Factories.insert!(:creator)

      %{submission_id: submission_id, promotion_id: promotion_id} =
        Advert.Factories.create_advert(creator, :accepted, 1)

      submission_id |> Pool.Public.get_by_submission!() |> promote_pool_to_panl!()

      {:ok, _view, html} = live(conn, ~m"/promotion/#{promotion_id}")
      assert html =~ "/images/logos/pools/panl_wide_dark.svg"
    end
  end
end
