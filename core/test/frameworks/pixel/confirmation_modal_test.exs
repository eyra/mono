defmodule Frameworks.Pixel.ConfirmationModalTest do
  @moduledoc """
  Covers the optional confirm_label / cancel_label assigns added so callers
  (e.g. the payout handoff) can use custom CTAs while reusing the shared modal.
  """
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.ConfirmationModal

  defp render_modal(assigns_overrides) do
    render_component(ConfirmationModal,
      id: "confirmation-modal-test",
      assigns: Map.merge(%{title: "Title", body: "Body"}, assigns_overrides)
    )
  end

  test "renders a custom confirm label" do
    assert render_modal(%{confirm_label: "Continue to verification"}) =~
             "Continue to verification"
  end

  test "renders a custom cancel label" do
    assert render_modal(%{cancel_label: "Niet nu"}) =~ "Niet nu"
  end

  test "renders the title and body" do
    html = render_modal(%{title: "Verification required", body: "You will leave Next"})
    assert html =~ "Verification required"
    assert html =~ "You will leave Next"
  end

  test "renders the confirm button as an external link when given an http_get action" do
    html =
      render_modal(%{
        confirm_label: "Continue to verification",
        confirm_action: %{type: :http_get, to: "https://opp.test/kyc"}
      })

    assert html =~ ~s(href="https://opp.test/kyc")
    assert html =~ "Continue to verification"
  end

  test "defaults the confirm button to a send event when no action is given" do
    html = render_modal(%{confirm_label: "Go"})
    # Default send action renders a phx-click, not an href to OPP.
    refute html =~ "https://opp.test"
    assert html =~ "phx-click"
  end
end
