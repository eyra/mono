defmodule Core.GreenLight.PrincipalTest do
  use ExUnit.Case, async: true
  alias GreenLight.Principal
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
  end
end
