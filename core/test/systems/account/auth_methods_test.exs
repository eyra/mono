defmodule Systems.Account.AuthMethodsTest do
  use ExUnit.Case, async: false

  alias Systems.Account.AuthMethods

  setup do
    account = Application.fetch_env!(:core, :account)

    Application.put_env(
      :core,
      :account,
      Keyword.put(account, :auth_methods, %{
        surfconext: %{provider: true, satellite: true},
        google: %{provider: true, satellite: true, mx_provider: "google"},
        email: %{provider: false, satellite: true},
        mock: %{provider: true, satellite: false}
      })
    )

    on_exit(fn -> Application.put_env(:core, :account, account) end)
    :ok
  end

  test "derives satellite modules" do
    assert AuthMethods.satellites() == %{
             surfconext: Systems.Account.Identity.Surfconext.UserModel,
             google: Systems.Account.Identity.Google.UserModel,
             email: Systems.Account.Identity.Email.UserModel
           }
  end

  test "returns providers and satellite-backed providers" do
    assert Enum.sort(AuthMethods.providers()) == [:google, :mock, :surfconext]
    assert Enum.sort(AuthMethods.satellite_providers()) == [:google, :surfconext]
  end

  test "returns a satellite module" do
    assert AuthMethods.satellite(:google) == Systems.Account.Identity.Google.UserModel
  end

  test "routes supported MX providers" do
    assert AuthMethods.provider_for_mx_provider("google") == :google
    assert AuthMethods.provider_for_mx_provider("microsoft") == nil
    assert AuthMethods.provider_for_mx_provider(nil) == nil
  end
end
