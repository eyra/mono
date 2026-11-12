defmodule NextWeb.Features.AuthIdentifyErrorTest do
  @moduledoc """
  An error message under the email field on the sign-in code page stays fully
  visible: a message that wraps to more lines pushes the continue button down
  instead of running behind it. Like our other forms, the sign-in code page and
  the code entry page keep 24px between the field and the continue button, and
  with an error 8px above the message and 24px below it. Submitting with an
  error on screen keeps the field focused, so a phone's keyboard stays up, and
  keeps the message in its place.
  """
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Mica.Repo
  alias Systems.Account.AuthCodeLimits
  alias Systems.Account.AuthCodeModel
  alias Systems.Rate

  @email_field "[data-testid='auth-email-input']"
  @email_error "#email_error_message"
  @email_button "[data-testid='auth-continue-button']"
  @code_field "[data-testid='auth-code-input']"
  @code_error "[data-testid='auth-code-error']"
  @code_button "[data-testid='auth-code-verify-button']"

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
    # The email address's daily total refuses the requests; a browser test
    # takes seconds, well within the module's 120 s timeout.
    Rate.TestHelper.wait_out_window_end(86_400, 60_000)
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
  feature "without an error the continue button sits 24px under the field", %{session: session} do
    session
    |> visit("/user/auth/verify?email=gap@example.com")
    |> assert_has(Query.css(".phx-connected #{@code_field}"))

    assert gap(session, @code_field, @code_button) == 24

    for path <- ["/user/auth/identify/participant", "/user/auth/identify"] do
      session
      |> visit(path)
      |> assert_has(Query.css(".phx-connected #{@email_field}"))

      assert gap(session, @email_field, @email_button) == 24, path
    end
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "with an error the message sits 8px under the field and 24px above the button", %{
    session: session
  } do
    email = "wrong-code-#{System.unique_integer([:positive])}@example.com"
    {_code, auth_code} = AuthCodeModel.build(email, nil)
    Repo.insert!(auth_code)

    session
    |> visit("/user/auth/verify?email=#{email}")
    |> assert_has(Query.css(".phx-connected #{@code_field}"))

    for i <- 0..5,
        do: fill_in(session, Query.css("[data-testid='auth-code-cell-#{i}']"), with: "9")

    session |> assert_has(Query.css(@code_error))

    assert {gap(session, @code_field, @code_error), gap(session, @code_error, @code_button)} ==
             {8, 24}

    for path <- ["/user/auth/identify/participant", "/user/auth/identify"] do
      limited = "limited-#{System.unique_integer([:positive])}@example.com"
      Stream.repeatedly(fn -> AuthCodeLimits.count_request?(limited) end) |> Enum.find(&(!&1))

      session
      |> visit(path)
      |> assert_has(Query.css(".phx-connected #{@email_field}"))
      |> fill_in(Query.css(@email_field), with: limited)
      |> click(Query.css(@email_button))
      |> assert_has(Query.css(@email_error))

      assert {gap(session, @email_field, @email_error), gap(session, @email_error, @email_button)} ==
               {8, 24},
             path
    end
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "submitting again with a message keeps the field focused and the message in place",
          %{session: session} do
    limited = "limited-#{System.unique_integer([:positive])}@example.com"
    Stream.repeatedly(fn -> AuthCodeLimits.count_request?(limited) end) |> Enum.find(&(!&1))

    session
    |> visit("/user/auth/identify/participant")
    |> assert_has(Query.css(".phx-connected #{@email_field}"))
    |> fill_in(Query.css(@email_field), with: limited)
    |> click(Query.css(@email_button))
    |> assert_has(Query.css(@email_error))
    |> execute_script(
      """
      const input = document.querySelector(arguments[0]);
      input.focus();
      window.changes = [];
      input.addEventListener("blur", () => window.changes.push("field blurred"));
      new MutationObserver((mutations) => {
        for (const mutation of mutations) {
          if (mutation.type === "attributes") window.changes.push("field readonly");
          for (const node of mutation.removedNodes) {
            if (node.id === "email_error_message") window.changes.push("message removed");
            if (node.matches?.("[data-button-loading]")) document.body.dataset.settled = "";
          }
        }
      }).observe(input.form, {childList: true, subtree: true, attributes: true, attributeFilter: ["readonly"]});
      """,
      [@email_field]
    )
    |> send_keys(Query.css(@email_field), [:enter])
    |> assert_has(Query.css("body[data-settled]"))
    |> assert_has(Query.css(@email_error))
    |> execute_script(
      "return {changes: window.changes, active: document.activeElement.dataset.testid};",
      fn result -> send(self(), {:after_submit, result}) end
    )

    assert_received {:after_submit, %{"changes" => [], "active" => "auth-email-input"}}
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "a wrong code keeps the form usable and ends the loading feedback", %{session: session} do
    email = "focus-code-#{System.unique_integer([:positive])}@example.com"
    {_code, auth_code} = AuthCodeModel.build(email, nil)
    Repo.insert!(auth_code)

    session
    |> visit("/user/auth/verify?email=#{email}")
    |> assert_has(Query.css(".phx-connected #{@code_field}"))

    for i <- 0..4,
        do: fill_in(session, Query.css("[data-testid='auth-code-cell-#{i}']"), with: "9")

    session
    |> execute_script("""
    window.changes = [];
    new MutationObserver((mutations) => {
      for (const mutation of mutations) window.changes.push(mutation.attributeName);
    }).observe(document.getElementById("auth_code_form"), {subtree: true, attributes: true, attributeFilter: ["readonly", "disabled"]});
    """)
    |> fill_in(Query.css("[data-testid='auth-code-cell-5']"), with: "9")
    |> assert_has(Query.css(@code_error))
    |> refute_has(Query.css("#{@code_button} .prism-button--loading"))
    |> execute_script(
      "return {changes: window.changes, active: document.activeElement.dataset.testid};",
      fn result -> send(self(), {:after_submit, result}) end
    )

    assert_received {:after_submit, %{"changes" => [], "active" => "auth-code-cell-0"}}
  end

  @sessions [[capabilities: @phone_nl_capabilities]]
  @tag :feature
  feature "a submit while disconnected doesn't block the next one", %{session: session} do
    email = "reconnect-#{System.unique_integer([:positive])}@example.com"

    session
    |> visit("/user/auth/identify/participant")
    |> assert_has(Query.css(".phx-connected #{@email_field}"))
    |> fill_in(Query.css(@email_field), with: email)
    |> execute_script("window.liveSocket.disconnect();")
    |> assert_has(Query.css("[data-phx-main].phx-error"))
    |> send_keys(Query.css(@email_field), [:enter])
    |> refute_has(Query.css("#{@email_button} .prism-button--loading"))
    |> execute_script("window.liveSocket.connect();")
    |> assert_has(Query.css(".phx-connected #{@email_field}"))
    |> send_keys(Query.css(@email_field), [:enter])
    |> assert_has(Query.css(@code_field))
  end

  defp gap(session, upper, lower) do
    session
    |> execute_script(
      """
      const upper = document.querySelector(arguments[0]).getBoundingClientRect();
      const lower = document.querySelector(arguments[1]).getBoundingClientRect();
      return lower.top - upper.bottom;
      """,
      [upper, lower],
      &send(self(), {:gap, &1})
    )

    assert_received {:gap, gap}
    gap
  end
end
