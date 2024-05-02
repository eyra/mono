defmodule Systems.Advert.SwitchTest do
  use Core.DataCase, async: true
  alias Core.Factories
  alias Core.Authorization
  alias Ecto.Changeset
  alias Core.Accounts.User

  alias Systems.Advert.Switch

  setup do
    {:ok,
     %{
       advert: Factories.insert!(:advert),
       coordinator: Factories.insert!(:member, %{coordinator: true})
     }}
  end

  describe "advert_created" do
    test "assign the coordinator role on newly created studies", %{
      advert: advert,
      coordinator: coordinator
    } do
      Switch.intercept({:advert, :created}, %{
        advert: advert,
        from_pid: self()
      })

      assert Authorization.users_with_role(advert, :coordinator, [:profile, :features]) == [
               coordinator
             ]
    end
  end

  describe "user_profile_updated" do
    test "assign the coordinator role on all existing adverts", %{
      advert: advert,
      coordinator: coordinator
    } do
      Switch.intercept({:user_profile, :updated}, %{
        user: coordinator,
        user_changeset: Changeset.cast(%User{}, %{coordinator: true}, [:coordinator])
      })

      assert Authorization.users_with_role(advert, :coordinator, [:profile, :features]) == [
               coordinator
             ]
    end

    test "do not assign coordinator role to students/researchers", %{
      advert: advert
    } do
      student = Factories.insert!(:member, %{student: true})

      Switch.intercept({:user_profile, :updated}, %{
        user: student,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(advert, :coordinator) == []
    end

    test "remove the coordinator role on all existing adverts", %{
      advert: advert
    } do
      user = Factories.insert!(:member)
      Authorization.assign_role(user, advert, :coordinator)

      Switch.intercept({:user_profile, :updated}, %{
        user: user,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(advert, :coordinator) == []
    end
  end
end
