defmodule CoreWeb.Features.Auth.IdentityProviderTransferTest do
  use CoreWeb.FeatureCase

  alias Core.Repo
  alias Systems.Account.Auth.Email.UserModel

  setup do
    account = Application.get_env(:core, :account, [])
    original = Keyword.get(account, :auth_methods, %{})

    Application.put_env(
      :core,
      :account,
      Keyword.put(
        account,
        :auth_methods,
        Map.put(original, :mock, %{provider: true, satellite: false})
      )
    )

    on_exit(fn ->
      account = Application.get_env(:core, :account, [])
      Application.put_env(:core, :account, Keyword.put(account, :auth_methods, original))
    end)

    :ok
  end

  @tag :feature
  feature "decline clears a Mock transfer", %{session: session} do
    Factories.insert!(:creator, %{
      email: "decline@mock.com",
      confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })

    session
    |> visit("/auth/mock/callback?email=decline@mock.com")
    |> assert_has(Query.css("[data-testid='idp-transfer-page']"))
    |> click(Query.css("[data-testid='idp-transfer-decline']"))
    |> assert_has(Query.css("[data-testid='auth-email-input']"))
  end

  @tag :feature
  feature "confirm removes existing authentication satellites", %{session: session} do
    user =
      Factories.insert!(:creator, %{
        email: "confirm@mock.com",
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

    Factories.insert!(:email_user, %{user_id: user.id})
    Factories.insert!(:google_user, %{user_id: user.id, sub: "confirm-google-sub"})

    session
    |> visit("/auth/mock/callback?email=confirm@mock.com")
    |> assert_has(Query.css("[data-testid='idp-transfer-page']"))
    |> click(Query.css("[data-testid='idp-transfer-confirm']"))
    |> assert_path_changed_from("/auth/mock/transfer")

    refute Repo.get_by(UserModel, user_id: user.id)
    refute Repo.get_by(Systems.Account.Auth.Google.UserModel, user_id: user.id)
  end
end
