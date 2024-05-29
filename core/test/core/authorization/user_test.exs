defmodule Core.GreenLight.PrincipalTest do
  use ExUnit.Case, async: true
  alias Frameworks.GreenLight.Principal
  alias Systems.Account.User

  describe "roles/1" do
    test "user gets the member role" do
      assert Principal.roles(%User{}) == MapSet.new([:member])
    end

    test "creator gets additional creator role" do
      assert Principal.roles(%User{creator: true}) == MapSet.new([:member, :creator])
    end

    test "member gets no additional roles" do
      assert Principal.roles(%User{creator: false}) == MapSet.new([:member])
    end

    test "user gets admin when listed in the config" do
      current_env = Application.get_env(:core, :features, [])
      current_admins = Application.get_env(:core, :admins, [])

      on_exit(fn ->
        Application.put_env(:core, Core.SurfConext, current_env)
        Application.put_env(:core, :admins, current_admins)
      end)

      Application.put_env(
        :core,
        :admins,
        Systems.Admin.Public.compile(["admin@example.org"])
      )

      # Regular member
      assert Principal.roles(%User{email: "regular@example.org"}) == MapSet.new([:member])
      # Admin user
      assert Principal.roles(%User{email: "admin@example.org"}) == MapSet.new([:member, :admin])
    end
  end
end
