defmodule Core.Pools.SignalHandlersTest do
  use Core.DataCase, async: true
  alias Core.Factories
  alias Core.Pools.SignalHandlers
  alias Core.Authorization
  alias Ecto.Changeset
  alias Core.Accounts.User

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
      SignalHandlers.dispatch(:campaign_created, %{
        campaign: campaign
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
      SignalHandlers.dispatch(:user_profile_updated, %{
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

      SignalHandlers.dispatch(:user_profile_updated, %{
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

      SignalHandlers.dispatch(:user_profile_updated, %{
        user: user,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(campaign, :coordinator) == []
    end
  end
end
