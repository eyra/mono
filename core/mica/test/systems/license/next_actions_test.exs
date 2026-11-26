defmodule Systems.License.NextActionsTest do
  @moduledoc """
  UC-LINK-02 part 2: the researcher is told when support gives a license or
  switches one off, reminded from 14 days before its end date, and told once
  it has ended. The To-dos'
  copy is tested in Self's suite (`MicaSaas.Systems.License.ToDoTest`), which
  has an endpoint to build their links.
  """
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test
  use Oban.Testing, repo: Mica.Repo

  alias Systems.License
  alias Systems.License.NextActions.Ended
  alias Systems.License.NextActions.Given
  alias Systems.License.NextActions.Reminder
  alias Systems.License.NextActions.SwitchedOff
  alias Systems.NextAction
  alias Systems.Notify

  @now ~U[2026-11-26 12:00:00Z]

  setup do
    set_feature_flag(:panl_post_launch, true)

    %{
      admin: Factories.insert!(:admin, %{email: "admin1@example.org"}),
      researcher: Factories.insert!(:creator)
    }
  end

  # The researcher's To-dos as stored: {type, license, end date}.
  defp to_dos(%{id: user_id}) do
    from(na in NextAction.Model, where: na.user_id == ^user_id, order_by: [na.action, na.key])
    |> Repo.all()
    |> Enum.map(fn %{action: action, params: params} ->
      {String.to_existing_atom(action), String.to_existing_atom(params["license"]),
       params["valid_until"]}
    end)
  end

  defp give(admin, researcher, changes), do: License.Public.save(admin, researcher, changes, @now)

  # As clicking the To-do's button does (`Notify.Public.open_message/2`, tested
  # in Self's suite, which can build the button's path).
  defp mark_read(user) do
    for license <- [:publish, :pay_in] do
      {:ok, _} = Notify.Public.mark_seen(user, correlation_id: "license:#{license}")
    end
  end

  defp notifications(%{id: user_id}) do
    from(m in Notify.MessageModel,
      join: e in Notify.EventModel,
      on: e.id == m.event_id,
      where: e.subject_user_id == ^user_id,
      order_by: m.id,
      select: %{type: e.type, actor_user_id: e.actor_user_id, status: m.status}
    )
    |> Repo.all()
  end

  describe "when support gives a license" do
    test "the researcher is told which license and until when",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{pay_in: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == [{Given, :pay_in, "2027-11-26"}]
    end

    test "each license given gets its own To-do", %{admin: admin, researcher: researcher} do
      :ok =
        give(admin, researcher, %{
          pay_in: {:on, ~D[2027-11-26]},
          publish: {:on, ~D[2027-02-24]}
        })

      assert to_dos(researcher) == [
               {Given, :pay_in, "2027-11-26"},
               {Given, :publish, "2027-02-24"}
             ]
    end

    test "giving it again tells the new end date in the same To-do",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-26]}})
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
    end

    test "the reminder goes away and the new end date is told",
         %{admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-05]})
      1 = License.Public.remind(@now)
      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-05"}]

      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
    end

    test "a license given by no one (the transition, a seed) isn't told",
         %{researcher: researcher} do
      {:ok, _} = License.Public.grant(researcher, :publish, ~D[2027-02-24])

      assert to_dos(researcher) == []
    end

    test "a refused save tells nothing", %{researcher: researcher} do
      assert {:error, :forbidden} =
               give(researcher, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == []
    end

    test "an invalid end date tells nothing", %{admin: admin, researcher: researcher} do
      assert {:error, {:end_date_not_in_future, :publish}} =
               give(admin, researcher, %{publish: {:on, ~D[2026-11-26]}})

      assert to_dos(researcher) == []
    end
  end

  describe "when support switches a license off" do
    test "the researcher is told which license", %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{pay_in: {:on, ~D[2027-11-26]}})
      :ok = give(admin, researcher, %{pay_in: :off})

      assert to_dos(researcher) == [{SwitchedOff, :pay_in, nil}]
    end

    test "it replaces the reminder", %{admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-05]})
      1 = License.Public.remind(@now)

      :ok = give(admin, researcher, %{publish: :off})

      assert to_dos(researcher) == [{SwitchedOff, :publish, nil}]
    end

    test "switching off a license that isn't on tells nothing",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: :off})

      assert to_dos(researcher) == []
    end

    test "switching off a license past its end date tells nothing",
         %{admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})

      :ok = give(admin, researcher, %{publish: :off})

      assert to_dos(researcher) == []
    end

    test "giving it again replaces the switched-off To-do",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})
      :ok = give(admin, researcher, %{publish: :off})
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-02-24]}})

      assert to_dos(researcher) == [{Given, :publish, "2027-02-24"}]
    end

    test "the To-do of the other license stays", %{admin: admin, researcher: researcher} do
      :ok =
        give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}, pay_in: {:on, ~D[2027-11-26]}})

      :ok = give(admin, researcher, %{pay_in: :off})

      assert to_dos(researcher) == [
               {Given, :publish, "2027-11-26"},
               {SwitchedOff, :pay_in, nil}
             ]
    end
  end

  describe "remind/1" do
    test "reminds 14 days before the end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})

      assert License.Public.remind(@now) == 1
      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-10"}]
    end

    test "the reminder comes before the researcher's other To-dos", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})
      1 = License.Public.remind(@now)

      assert [%{priority: :high}] = Repo.all(NextAction.Model)
    end

    test "doesn't remind 15 days before the end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-11]})

      assert License.Public.remind(@now) == 0
      assert to_dos(researcher) == []
    end

    test "reminds a license that ends within 14 days when a daily run was missed",
         %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-26]})

      assert License.Public.remind(@now) == 1
    end

    test "reminds once", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})

      assert License.Public.remind(@now) == 1
      assert License.Public.remind(~U[2026-11-27 12:00:00Z]) == 0
      assert [%{count: 1}] = Repo.all(NextAction.Model)
    end

    test "replaces the To-do that told the license was given",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-26]}})

      assert License.Public.remind(~U[2026-12-12 12:00:00Z]) == 1
      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-26"}]
    end

    test "reminds a license given by no one (the transition)", %{researcher: researcher} do
      {:ok, _} = License.Public.grant(researcher, :publish, ~D[2026-12-10])

      assert License.Public.remind(@now) == 1
    end

    test "doesn't remind a license past its end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})

      assert License.Public.remind(@now) == 0
    end

    test "doesn't remind a license switched off", %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-10]}})
      :ok = give(admin, researcher, %{publish: :off})

      assert License.Public.remind(@now) == 0
      assert to_dos(researcher) == [{SwitchedOff, :publish, nil}]
    end

    test "reads only the newest record of the license", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        valid_until: ~D[2026-12-10],
        granted_at: ~U[2026-01-01 12:00:00Z]
      })

      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})

      assert License.Public.remind(@now) == 0
    end

    test "reminds of Pay-in with :panl_post_launch", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        license: :pay_in,
        valid_until: ~D[2026-12-10]
      })

      assert License.Public.remind(@now) == 1
      assert to_dos(researcher) == [{Reminder, :pay_in, "2026-12-10"}]
    end

    test "doesn't remind of Pay-in without :panl_post_launch", %{researcher: researcher} do
      set_feature_flag(:panl_post_launch, false)

      Factories.insert!(:license, %{
        user: researcher,
        license: :pay_in,
        valid_until: ~D[2026-12-10]
      })

      assert License.Public.remind(@now) == 0
    end

    test "counts the 14 days in Amsterdam time", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-15]})

      # 30 November 23:59 and 1 December 00:00 in Amsterdam
      assert License.Public.remind(~U[2026-11-30 22:59:00Z]) == 0
      assert License.Public.remind(~U[2026-11-30 23:00:00Z]) == 1
    end
  end

  describe "tell_ended/1" do
    test "tells the day after the end date, and replaces the reminder", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})
      1 = License.Public.remind(@now)

      assert License.Public.tell_ended(~U[2026-12-10 12:00:00Z]) == 0
      assert License.Public.tell_ended(~U[2026-12-11 12:00:00Z]) == 1
      assert to_dos(researcher) == [{Ended, :publish, "2026-12-10"}]
    end

    test "tells once", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})

      assert License.Public.tell_ended(@now) == 1
      assert License.Public.tell_ended(~U[2026-11-27 12:00:00Z]) == 0
      assert [%{count: 1}] = Repo.all(NextAction.Model)
    end

    test "doesn't tell again once the researcher has read it", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})
      1 = License.Public.tell_ended(@now)
      mark_read(researcher)

      assert License.Public.tell_ended(~U[2026-11-27 12:00:00Z]) == 0
    end

    test "counts the end date in Amsterdam time", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-30]})

      # 30 November 23:59 and 1 December 00:00 in Amsterdam
      assert License.Public.tell_ended(~U[2026-11-30 22:59:00Z]) == 0
      assert License.Public.tell_ended(~U[2026-11-30 23:00:00Z]) == 1
    end

    test "doesn't tell about a license switched off", %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-10]}})
      :ok = give(admin, researcher, %{publish: :off})

      assert License.Public.tell_ended(~U[2026-12-12 12:00:00Z]) == 0
      assert to_dos(researcher) == [{SwitchedOff, :publish, nil}]
    end

    test "doesn't tell about a license given again", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        valid_until: ~D[2026-11-25],
        granted_at: ~U[2026-01-01 12:00:00Z]
      })

      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})

      assert License.Public.tell_ended(@now) == 0
    end

    test "giving the license again replaces it", %{admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})
      1 = License.Public.tell_ended(@now)

      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
    end

    test "tells about Pay-in only with :panl_post_launch", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        license: :pay_in,
        valid_until: ~D[2026-11-25]
      })

      set_feature_flag(:panl_post_launch, false)
      assert License.Public.tell_ended(@now) == 0

      set_feature_flag(:panl_post_launch, true)
      assert License.Public.tell_ended(@now) == 1
      assert to_dos(researcher) == [{Ended, :pay_in, "2026-11-25"}]
    end
  end

  describe "a To-do the researcher has read" do
    test "the reminder isn't created again", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})
      1 = License.Public.remind(@now)
      mark_read(researcher)

      assert License.Public.remind(~U[2026-11-27 12:00:00Z]) == 0
    end

    test "it no longer shows", %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-26]}})
      mark_read(researcher)

      assert to_dos(researcher) == []
    end

    test "a new To-do about the license shows again", %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-26]}})
      mark_read(researcher)

      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
    end
  end

  describe "the notifications" do
    test "are recorded as from support when support gives or switches off",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})
      :ok = give(admin, researcher, %{publish: :off})

      admin_id = admin.id

      assert [
               %{type: "license_given", actor_user_id: ^admin_id},
               %{type: "license_switched_off", actor_user_id: ^admin_id}
             ] = notifications(researcher)
    end

    test "are recorded as from no one when the daily job tells", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})
      1 = License.Public.remind(@now)

      assert [%{type: "license_reminder", actor_user_id: nil}] = notifications(researcher)
    end

    test "a new one marks the one it replaces seen, and keeps it",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})
      :ok = give(admin, researcher, %{publish: :off})

      assert [
               %{type: "license_given", status: :seen},
               %{type: "license_switched_off", status: :sent}
             ] = notifications(researcher)
    end

    test "about the other license stay unseen", %{admin: admin, researcher: researcher} do
      :ok =
        give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}, pay_in: {:on, ~D[2027-11-26]}})

      :ok = give(admin, researcher, %{pay_in: :off})

      assert Enum.count(notifications(researcher), &(&1.status == :seen)) == 1
    end
  end

  describe "License.ReminderWorker" do
    test "tells the users whose license has ended", %{researcher: researcher} do
      valid_until = Date.add(License.Public.today(), -1)
      Factories.insert!(:license, %{user: researcher, valid_until: valid_until})

      assert :ok = perform_job(License.ReminderWorker, %{})
      assert to_dos(researcher) == [{Ended, :publish, Date.to_iso8601(valid_until)}]
    end

    test "reminds the users whose license ends within 14 days", %{researcher: researcher} do
      valid_until = Date.add(License.Public.today(), 14)
      Factories.insert!(:license, %{user: researcher, valid_until: valid_until})

      assert :ok = perform_job(License.ReminderWorker, %{})
      assert to_dos(researcher) == [{Reminder, :publish, Date.to_iso8601(valid_until)}]
    end

    test "runs daily just after midnight in Amsterdam" do
      assert License.System.oban_crons() ==
               [license_reminder: {"5 23 * * *", License.ReminderWorker}]
    end
  end
end
