defmodule Systems.Campaign.SwitchTest do
  use Core.DataCase, async: true
  alias Core.Factories
  alias Core.Authorization
  alias Ecto.Changeset
  alias Core.Accounts.User

  alias Systems.Campaign.Switch

  setup do
    {:ok,
     %{
       campaign: Factories.insert!(:campaign),
       coordinator: Factories.insert!(:member, %{coordinator: true})
     }}
  end

  describe "campaign_created" do
    test "assign the coordinator role on newly created studies", %{
      campaign: campaign,
      coordinator: coordinator
    } do
      Switch.intercept({:campaign, :created}, %{
        campaign: campaign,
        from_pid: self()
      })

      assert Authorization.users_with_role(campaign, :coordinator, [:profile, :features]) == [
               coordinator
             ]
    end
  end

  describe "user_profile_updated" do
    test "assign the coordinator role on all existing campaigns", %{
      campaign: campaign,
      coordinator: coordinator
    } do
      Switch.intercept({:user_profile, :updated}, %{
        user: coordinator,
        user_changeset: Changeset.cast(%User{}, %{coordinator: true}, [:coordinator])
      })

      assert Authorization.users_with_role(campaign, :coordinator, [:profile, :features]) == [
               coordinator
             ]
    end

    test "do not assign coordinator role to students/researchers", %{
      campaign: campaign
    } do
      student = Factories.insert!(:member, %{student: true})

      Switch.intercept({:user_profile, :updated}, %{
        user: student,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(campaign, :coordinator) == []
    end

    test "remove the coordinator role on all existing campaigns", %{
      campaign: campaign
    } do
      user = Factories.insert!(:member)
      Authorization.assign_role(user, campaign, :coordinator)

      Switch.intercept({:user_profile, :updated}, %{
        user: user,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(campaign, :coordinator) == []
    end
  end
end
