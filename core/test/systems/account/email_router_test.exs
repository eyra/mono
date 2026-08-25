defmodule Systems.Account.EmailRouterTest do
  use Core.DataCase, async: false

  alias Core.Repo
  alias Systems.Account.EmailRouter

  setup do
    account = Application.get_env(:core, :account, [])
    original = Keyword.fetch!(account, :auth_methods)

    Application.put_env(
      :core,
      :account,
      Keyword.put(account, :auth_methods, %{
        surfconext: %{provider: true, satellite: true},
        google: %{provider: true, satellite: true, mx_provider: "google"},
        email: %{provider: false, satellite: true}
      })
    )

    on_exit(fn ->
      account = Application.get_env(:core, :account, [])
      Application.put_env(:core, :account, Keyword.put(account, :auth_methods, original))
    end)

    :ok
  end

  test "routes an existing account with a Google satellite without OTP" do
    user = Factories.insert!(:creator, %{email: "existing-google@custom-domain.test"})

    %Systems.Account.Identity.Google.UserModel{}
    |> Systems.Account.Identity.Google.UserModel.changeset(%{sub: "existing-google-sub"})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert!()

    assert EmailRouter.route(user.email) == :google
  end

  test "routes an existing account with a SURFconext satellite without OTP" do
    user = Factories.insert!(:creator, %{email: "existing-surf@custom-domain.test"})

    {:ok, _satellite} =
      Systems.Account.Identity.Surfconext.attach(user, %{
        "sub" => "existing-surf-sub",
        "email" => user.email
      })

    assert EmailRouter.route(user.email) == :surfconext
  end

  test "ignores an Email satellite when selecting an IdP" do
    user = Factories.insert!(:creator, %{email: "email-only@custom-domain.test"})
    Factories.insert!(:email_user, %{user_id: user.id})

    assert EmailRouter.route(user.email) == :otp
  end

  test "routes an unknown email to its supported UserCheck MX provider" do
    assert EmailRouter.route("google@custom-domain.test") == :google
  end

  test "falls back to OTP when UserCheck has no supported provider" do
    assert EmailRouter.route("unknown-#{System.unique_integer([:positive])}@custom-domain.test") ==
             :otp
  end
end
