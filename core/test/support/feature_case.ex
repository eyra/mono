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
  """
  def sign_in(session, user, password) do
    import Wallaby.Browser
    import Wallaby.Query

    session =
      session
      |> visit("/user/signin")
      |> fill_in(css("[data-testid='signin-email-input']"), with: user.email)
      |> fill_in(css("[data-testid='signin-password-input']"), with: password)
      |> click(css("[data-testid='signin-submit-button']"))
      # Wait for the post-login LiveView to be fully connected. That signal
      # proves the auth cookie was set, the destination LiveView mounted,
      # and its WebSocket is up. We deliberately DO NOT add
      # refute_has(signin-form) before this: refute_has polls the full
      # max_wait_time even when the element is already absent (Wallaby's
      # Browser.retry design), which floods chromedriver with hundreds of
      # HTTP requests per sign_in. With multiple sign_ins in a suite, that
      # backlog surfaces as HTTPoison :timeout on the next visit.
      |> assert_has(css("[data-phx-main].phx-connected"))

    session
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
