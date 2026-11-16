defmodule Systems.Account.Auth.MethodsTest do
  use ExUnit.Case, async: false

  alias Systems.Account.Auth.Methods

  setup do
    # Mica's own suite configures no SaaS, so no account config.
    account = Application.get_env(:mica, :account)

    Application.put_env(
      :mica,
      :account,
      Keyword.put(account || [], :auth_methods, %{
        surfconext: %{provider: true, satellite: true},
        centerdata: %{provider: true, satellite: true},
        google: %{provider: true, satellite: true, mx_provider: "google"},
        email: %{provider: false, satellite: true},
        mock: %{provider: true, satellite: false}
      })
    )

    on_exit(fn ->
      if account,
        do: Application.put_env(:mica, :account, account),
        else: Application.delete_env(:mica, :account)
    end)

    :ok
  end

  test "derives satellite modules" do
    assert Methods.satellites() == %{
             surfconext: Systems.Account.Auth.Surfconext.UserModel,
             centerdata: Systems.Account.Auth.Centerdata.UserModel,
             google: Systems.Account.Auth.Google.UserModel,
             email: Systems.Account.Auth.Email.UserModel
           }
  end

  test "returns providers and satellite-backed providers" do
    assert Enum.sort(Methods.providers()) == [:centerdata, :google, :mock, :surfconext]
    assert Enum.sort(Methods.satellite_providers()) == [:centerdata, :google, :surfconext]
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
