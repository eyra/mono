defmodule CoreWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  browser-based feature tests using Wallaby.

  Feature tests run a real browser to test the application
  from the user's perspective.

  ## Usage

      use CoreWeb.FeatureCase

  ## Running tests

  Feature tests require ChromeDriver to be installed and running:

      # Install ChromeDriver (macOS)
      brew install chromedriver

      # Run feature tests (headless by default)
      mix test test/features

      # Run with visible browser for debugging
      WALLABY_HEADLESS=false mix test test/features
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query
      import CoreWeb.FeatureCase

      alias Core.Factories
      alias Core.Repo

      # Feature tests drive a real headless Chrome via chromedriver. Under
      # full-suite load chromedriver intermittently takes 30–60s to ack a
      # single /url POST (Wallaby gotcha — recv_timeout is :infinity in
      # config/test.exs so a real hang is caught by this ExUnit timeout
      # rather than a false-positive HTTPoison error). 120s gives that
      # natural variability headroom while still failing hard on a genuine
      # hang.
      @moduletag timeout: 120_000
    end
  end

  # Note: We do NOT add a manual setup block here.
  # Wallaby.Feature handles session creation automatically, including:
  # - Single session via `%{session: session}` in feature tests
  # - Multiple sessions via `@sessions N` and `%{sessions: [s1, s2, ...]}` in feature tests
  # - Ecto sandbox checkout for database isolation

  @doc """
  Signs in a user through the browser login form.

  Post-signin destination varies by user type (participant → home,
  creator → projects, etc.), so we wait on URL change rather than a
  destination data-testid. See `assert_path_changed_from/3`.
  """
  def sign_in(session, user, password) do
    import Wallaby.Browser
    import Wallaby.Query

    session
    |> visit("/user/signin")
    |> fill_in(css("[data-testid='signin-email-input']"), with: user.email)
    |> fill_in(css("[data-testid='signin-password-input']"), with: password)
    |> click(css("[data-testid='signin-submit-button']"))
    |> assert_path_changed_from("/user/signin")
  end

  @doc """
  Polls until the current URL path is no longer `from_path`. Use after an
  action that navigates when the destination path varies (e.g., post-signin
  landing depends on user type).

  Mirrors Playwright's `page.waitForURL` and Cypress's `cy.url().should(...)`.
  URL changes are atomic, so this is race-free — no DOM polling, no
  stale-element exposure. Works for full page loads AND LiveView
  `push_navigate` / `push_patch` (both update `window.location` via
  `history.pushState`).

  Does NOT apply to in-page LiveView updates that don't change the URL
  (modal open, save-in-place, etc.) — use `assert_has(destination-testid)`
  for those.
  """
  def assert_path_changed_from(session, from_path, timeout \\ 5_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_path_change(session, from_path, deadline)
  end

  defp do_wait_path_change(session, from_path, deadline) do
    case Wallaby.Browser.current_path(session) do
      ^from_path ->
        if System.monotonic_time(:millisecond) > deadline do
          raise Wallaby.ExpectationNotMetError,
            message: "Expected URL path to change from #{from_path}"
        end

        Process.sleep(50)
        do_wait_path_change(session, from_path, deadline)

      _ ->
        session
    end
  end

  @doc """
  Creates a confirmed user and signs them in.
  Returns the session and the user.
  """
  def sign_in_as_new_user(session) do
    password = Core.Factories.valid_user_password()

    user =
      Core.Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    session = sign_in(session, user, password)

    {session, user}
  end

  @doc """
  Creates a confirmed user with a specific role.
  """
  def create_confirmed_user(email, password, opts \\ []) do
    creator = Keyword.get(opts, :creator, false)

    Core.Factories.insert!(:member, %{
      email: email,
      password: password,
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      creator: creator
    })
  end

  @doc """
  Retries a block of Wallaby interactions when a StaleReferenceError occurs.

  LiveView may morph the DOM between a `find` and a `click`, causing the
  element reference to become stale. This macro retries the entire block
  (find + action) as an atomic unit, matching the retry-on-stale strategy
  used by Playwright and Cypress.

  ## Example

      retry_stale do
        session |> click(Query.css("[data-testid='my-button']"))
      end
  """
  defmacro retry_stale(do: block) do
    quote do
      CoreWeb.FeatureCase.do_retry_stale(fn -> unquote(block) end)
    end
  end

  @doc false
  def do_retry_stale(fun, attempts \\ 5)
  def do_retry_stale(fun, 1), do: fun.()

  def do_retry_stale(fun, attempts) do
    fun.()
  rescue
    Wallaby.StaleReferenceError ->
      do_retry_stale(fun, attempts - 1)
  end
end
