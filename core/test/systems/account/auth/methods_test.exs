defmodule Systems.Account.Auth.MethodsTest do
  use ExUnit.Case, async: false

  alias Systems.Account.Auth.Methods

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
    assert Methods.satellites() == %{
             surfconext: Systems.Account.Auth.Surfconext.UserModel,
             google: Systems.Account.Auth.Google.UserModel,
             email: Systems.Account.Auth.Email.UserModel
           }
  end

  test "returns providers and satellite-backed providers" do
    assert Enum.sort(Methods.providers()) == [:google, :mock, :surfconext]
    assert Enum.sort(Methods.satellite_providers()) == [:google, :surfconext]
  end

  test "returns a satellite module" do
    assert Methods.satellite(:google) == Systems.Account.Auth.Google.UserModel
  end

  test "routes supported MX providers" do
    assert Methods.provider_for_mx_provider("google") == :google
    assert Methods.provider_for_mx_provider("microsoft") == nil
    assert Methods.provider_for_mx_provider(nil) == nil
  end
end
