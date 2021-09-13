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
       study: Factories.insert!(:study),
       coordinator: Factories.insert!(:member, %{coordinator: true})
     }}
  end

  describe "study_created" do
    test "assign the coordinator role on newly created studies", %{
      study: study,
      coordinator: coordinator
    } do
      SignalHandlers.dispatch(:study_created, %{
        study: study
      })

      assert Authorization.users_with_role(study, :coordinator, [:profile]) == [coordinator]
    end
  end

  describe "user_profile_updated" do
    test "assign the coordinator role on all existing studyies", %{
      study: study,
      coordinator: coordinator
    } do
      SignalHandlers.dispatch(:user_profile_updated, %{
        user: coordinator,
        user_changeset: Changeset.cast(%User{}, %{coordinator: true}, [:coordinator])
      })

      assert Authorization.users_with_role(study, :coordinator, [:profile]) == [coordinator]
    end

    test "do not assign coordinator role to students/researchers", %{
      study: study
    } do
      student = Factories.insert!(:member, %{student: true})

      SignalHandlers.dispatch(:user_profile_updated, %{
        user: student,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(study, :coordinator) == []
    end

    test "remove the coordinator role on all existing studyies", %{
      study: study
    } do
      user = Factories.insert!(:member)
      Authorization.assign_role(user, study, :coordinator)

      SignalHandlers.dispatch(:user_profile_updated, %{
        user: user,
        user_changeset: Changeset.cast(%User{}, %{coordinator: false}, [:coordinator])
      })

      assert Authorization.users_with_role(study, :coordinator) == []
    end
  end
end
