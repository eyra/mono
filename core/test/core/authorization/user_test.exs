defmodule Core.GreenLight.PrincipalTest do
  use ExUnit.Case, async: true
  alias Frameworks.GreenLight.Principal
  alias Core.Accounts.User

  describe "roles/1" do
    test "user gets the member role" do
      assert Principal.roles(%User{}) == MapSet.new([:member])
    end

    test "researcher gets additional researcher role" do
      assert Principal.roles(%User{researcher: true}) == MapSet.new([:member, :researcher])
    end

    test "student gets additional researcher role" do
      assert Principal.roles(%User{student: true}) == MapSet.new([:member, :student])
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
        Core.Admin.compile(["admin@example.org"])
      )

      # Regular member
      assert Principal.roles(%User{email: "regular@example.org"}) == MapSet.new([:member])
      # Admin user
      assert Principal.roles(%User{email: "admin@example.org"}) == MapSet.new([:member, :admin])
    end
  end
end
