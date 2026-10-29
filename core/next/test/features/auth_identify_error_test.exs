defmodule CoreWeb.Features.AuthIdentifyErrorTest do
  @moduledoc """
  An error message under the email field on the sign-in code page stays fully
  visible: a message that wraps to more lines pushes the continue button down
  instead of running behind it. Without an error, the continue button keeps the
  same gap below the field as on the code entry page.
  """
  use CoreWeb.FeatureCase
  use Core.FeatureFlags.Test

  alias Systems.Account.AuthCodeLimits

  # Headless Chrome keeps its window at least 500px wide; the device metrics
  # give the page a phone's width.
  @phone_nl_capabilities %{
    chromeOptions: %{
      args: [
        "--lang=nl-NL",
        "--headless",
        "--no-sandbox",
        "--disable-dev-shm-usage",
        "--disable-gpu"
      ],
      prefs: %{"intl.accept_languages" => "nl-NL,nl"},
      mobileEmulation: %{deviceMetrics: %{width: 360, height: 800, pixelRatio: 1}}
    }
  }

  setup do
    set_feature_flag(:otp, true)
    :ok
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "a message over more lines pushes the continue button down", %{session: session} do
    email = "limited-#{System.unique_integer([:positive])}@example.com"
    Stream.repeatedly(fn -> AuthCodeLimits.count_request?(email) end) |> Enum.find(&(!&1))

    session
    |> visit("/user/auth/identify/participant")
    |> assert_has(Query.css(".phx-connected [data-testid='auth-email-input']"))
    |> fill_in(Query.css("[data-testid='auth-email-input']"), with: email)
    |> click(Query.css("[data-testid='auth-continue-button']"))
    |> assert_has(Query.css("#email_error_message", text: "Wacht even"))
    |> execute_script(
      """
      const message = document.getElementById("email_error_message").getBoundingClientRect();
      const button = document.querySelector("[data-testid='auth-continue-button']").getBoundingClientRect();
      return {lines: Math.round(message.height / 18), gap: button.top - message.bottom};
      """,
      fn %{"lines" => lines, "gap" => gap} ->
        assert lines > 1
        assert gap >= 0
      end
    )
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "without an error the continue button keeps the gap of the code entry page", %{
    session: session
  } do
    verify_gap =
      session
      |> visit("/user/auth/verify?email=gap@example.com")
      |> assert_has(Query.css(".phx-connected [data-testid='auth-code-input']"))
      |> gap("auth-code-input", "auth-code-verify-button")

    assert verify_gap == 32

    for path <- ["/user/auth/identify/participant", "/user/auth/identify"] do
      identify_gap =
        session
        |> visit(path)
        |> assert_has(Query.css(".phx-connected [data-testid='auth-email-input']"))
        |> gap("auth-email-input", "auth-continue-button")

      assert identify_gap == verify_gap, "#{path}: #{identify_gap}px, code entry: #{verify_gap}px"
    end
  end

  defp gap(session, field_testid, button_testid) do
    session
    |> execute_script(
      """
      const field = document.querySelector(`[data-testid='${arguments[0]}']`).getBoundingClientRect();
      const button = document.querySelector(`[data-testid='${arguments[1]}']`).getBoundingClientRect();
      return button.top - field.bottom;
      """,
      [field_testid, button_testid],
      &send(self(), {:gap, &1})
    )

    assert_received {:gap, gap}
    gap
  end
end
