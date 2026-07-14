defmodule CoreWeb.Features.PromotionApplyAsVisitorTest do
  @moduledoc """
  Feature test for FX#10094100454. A visitor clicking Apply on a
  promotion should not crash on `Pool.Public.add_participant!(pool, nil)`
  — instead they're funnelled through the auth identify page with a
  nested `return_to` that carries them all the way back to the
  assignment after they authenticate + accept the pool join consent:

      /user/auth/identify?return_to=/pool/<slug>/join?return_to=/assignment/<id>/apply

  Complements the unit test in `Systems.Advert.PromotionLandingPageBuilderTest`
  by exercising the real-browser click + Phoenix routing so the
  URL-encoding survives an actual round-trip.
  """
  use CoreWeb.FeatureCase
  use Core.FeatureFlags.Test

  alias Systems.Advert
  alias Systems.Pool

  setup do
    set_feature_flag(:otp, true)
    :ok
  end

  @tag :feature
  feature "anonymous visitor clicking Apply lands on auth identify with nested return_to",
          %{session: session} do
    _panl_pool = Pool.Assembly.get_or_create_panl()
    creator = Factories.insert!(:creator)

    %{promotion_id: promotion_id, submission_id: submission_id, assignment_id: assignment_id} =
      Advert.Factories.create_advert(creator, :accepted, 1)

    slug = Pool.Model.slug(Pool.Public.get_by_submission!(submission_id))

    # Pre-click wait on .phx-connected: the Apply button is a
    # <div phx-click="…"> that needs the LiveView JS handshake to be
    # attached before chromedriver's click event can be routed to the
    # server. There's no target-page testid to wait on yet (we're pre-
    # click), so this is the correct signal here — not a violation of
    # the "wait on destination after navigation" rule.
    session
    |> visit("/promotion/#{promotion_id}")
    |> assert_has(Query.css("[data-phx-main].phx-connected"))
    |> click(Query.css("[data-testid='promotion-apply-button-hero']"))
    |> assert_has(Query.css("[data-testid='auth-email-input']"))

    return_to =
      session
      |> Wallaby.Browser.current_url()
      |> URI.parse()
      |> Map.get(:query, "")
      |> URI.decode_query()
      |> Map.get("return_to")

    # Outer decode gives us the join URL with the inner return_to still
    # URL-encoded (that inner encoding gets decoded when Phoenix parses
    # the join URL's own query string on the next hop).
    inner_encoded = URI.encode_www_form("/assignment/#{assignment_id}/apply")

    assert return_to == "/pool/#{slug}/join?return_to=#{inner_encoded}"
  end
end
