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

  # A save, and the tell it enqueued (`License.TellWorker`) run as Oban would.
  defp give(admin, researcher, changes) do
    result = License.Public.save(admin, researcher, changes, @now)
    Oban.drain_queue(queue: :default)
    result
  end

  # As clicking the To-do's button does (`Notify.Public.open_message/2`, tested
  # in Self's suite, which can build the button's path).
  defp mark_read(user) do
    for license <- [:publish, :pay_in] do
      {:ok, _} = Notify.Public.mark_seen(user, correlation_id: "license:#{license}")
    end
  end

  defp xmin(table, id) do
    %{rows: [[xmin]]} = Repo.query!("SELECT xmin::text FROM #{table} WHERE id = $1", [id])
    xmin
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

    # As with the transition: every creator's license ends on the same day.
    test "reminds every user whose license ends on that day", %{researcher: researcher} do
      other = Factories.insert!(:creator)
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-10]})
      Factories.insert!(:license, %{user: other, valid_until: ~D[2026-12-10]})

      assert License.Public.remind(@now) == 2
      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-10"}]
      assert to_dos(other) == [{Reminder, :publish, "2026-12-10"}]
      assert License.Public.remind(~U[2026-11-27 12:00:00Z]) == 0
    end

    test "reminds again of the new end date after support extended the license",
         %{admin: admin, researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        valid_until: ~D[2026-12-05],
        granted_at: ~U[2026-01-01 12:00:00Z]
      })

      1 = License.Public.remind(@now)
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-20]}})

      assert License.Public.remind(~U[2026-12-07 12:00:00Z]) == 1
      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-20"}]
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

  # The save's tell is a job inserted in the save's transaction, so it can't be
  # lost after the save, and isn't done for a save that was rolled back.
  describe "the tell of a save" do
    test "is enqueued with the save", %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-11-26]}}, @now)

      assert_enqueued(
        worker: License.TellWorker,
        args: %{"user_id" => researcher.id, "license" => "publish", "by_id" => admin.id}
      )

      assert to_dos(researcher) == []
    end

    # Rows written in one transaction share its id (`xmin`). Under the test
    # sandbox the save's transaction is a savepoint with an id of its own, so a
    # job inserted after the save's commit would carry the test's id instead.
    test "is written in the save's own transaction", %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-11-26]}}, @now)

      [%{id: record_id}] = License.Public.list_records(researcher)
      [%Oban.Job{id: job_id}] = all_enqueued(worker: License.TellWorker)

      assert xmin("licenses", record_id) == xmin("oban_jobs", job_id)
    end

    test "isn't enqueued for a switch-off that changes nothing",
         %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: :off}, @now)

      refute_enqueued(worker: License.TellWorker)
    end

    test "running it twice tells once", %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-11-26]}}, @now)
      args = %{"user_id" => researcher.id, "license" => "publish", "by_id" => admin.id}

      assert :ok = perform_job(License.TellWorker, args)
      assert :ok = perform_job(License.TellWorker, args)

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
      assert [%{type: "license_given", status: :sent}] = notifications(researcher)
    end

    test "of a user who deleted their account does nothing", %{admin: admin} do
      args = %{"user_id" => -1, "license" => "publish", "by_id" => admin.id}

      assert :ok = perform_job(License.TellWorker, args)
    end
  end

  # Saves and the daily job tell one after the other per user and license, and
  # each tells what the license is when its turn comes. Real overlap can't run
  # under the test sandbox (one connection), so these replay the interleavings
  # in order: a tell that arrives late, after a newer save.
  describe "tells about one license, one at a time" do
    test "two saves, then their tells: one To-do about the current end date",
         %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-01-01]}}, @now)
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-06-01]}}, @now)

      Oban.drain_queue(queue: :default)

      assert to_dos(researcher) == [{Given, :publish, "2027-06-01"}]
      assert [%{type: "license_given", status: :sent}] = notifications(researcher)
    end

    test "a give and a switch-off, then their tells: one To-do that it is switched off",
         %{admin: admin, researcher: researcher} do
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-01-01]}}, @now)
      :ok = License.Public.save(admin, researcher, %{publish: :off}, @now)

      Oban.drain_queue(queue: :default)

      assert to_dos(researcher) == [{SwitchedOff, :publish, nil}]
      assert [%{type: "license_switched_off", status: :sent}] = notifications(researcher)
    end

    test "the daily job skips a license support gave again after the job read it",
         %{admin: admin, researcher: researcher} do
      read = Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-05]})
      :ok = give(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      assert :skipped =
               License.Public.tell_if_current(
                 researcher,
                 :publish,
                 read.id,
                 {:reminder, ~D[2026-12-05]}
               )

      assert to_dos(researcher) == [{Given, :publish, "2027-11-26"}]
    end

    test "the daily job skips a license support switched off after the job read it",
         %{admin: admin, researcher: researcher} do
      :ok = give(admin, researcher, %{publish: {:on, ~D[2026-12-10]}})
      read = License.Public.get_current(researcher, :publish)
      :ok = give(admin, researcher, %{publish: :off})

      assert :skipped =
               License.Public.tell_if_current(
                 researcher,
                 :publish,
                 read.id,
                 {:reminder, ~D[2026-12-10]}
               )

      assert to_dos(researcher) == [{SwitchedOff, :publish, nil}]
    end

    test "the daily job tells a license that is still as it read it", %{researcher: researcher} do
      read = Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-05]})

      assert :told =
               License.Public.tell_if_current(
                 researcher,
                 :publish,
                 read.id,
                 {:reminder, ~D[2026-12-05]}
               )

      assert to_dos(researcher) == [{Reminder, :publish, "2026-12-05"}]
    end

    test "the daily job tells an end date once, also when two runs read it",
         %{researcher: researcher} do
      read = Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-05]})

      tell = fn ->
        License.Public.tell_if_current(researcher, :publish, read.id, {:reminder, ~D[2026-12-05]})
      end

      assert :told = tell.()
      assert :skipped = tell.()
      assert [_] = notifications(researcher)
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
