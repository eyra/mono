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
    end
  end

  setup do
    # Note: Wallaby.Feature handles Ecto sandbox checkout automatically
    # We only need to start the session with sandbox metadata
    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Core.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)

    {:ok, session: session}
  end

  @doc """
  Signs in a user through the browser login form.
  """
  def sign_in(session, user, password) do
    import Wallaby.Browser
    import Wallaby.Query

    session
    |> visit("/user/signin")
    |> fill_in(text_field("Email"), with: user.email)
    |> fill_in(text_field("Password"), with: password)
    |> click(button("Sign in"))
  end

  @doc """
  Creates a confirmed user and signs them in.
  Returns the session and the user.
  """
  def sign_in_as_new_user(session) do
    password = Core.Factories.valid_user_password()

    user =
      Core.Factories.insert!(:member, %{password: password, confirmed_at: DateTime.utc_now()})

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
      confirmed_at: DateTime.utc_now(),
      creator: creator
    })
  end
end
