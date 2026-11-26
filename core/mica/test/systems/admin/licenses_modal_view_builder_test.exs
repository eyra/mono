defmodule Systems.Admin.LicensesModalViewBuilderTest do
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test

  alias Systems.Account
  alias Systems.Admin.LicensesModalViewBuilder
  alias Systems.License
  alias Systems.Org

  @now ~U[2026-11-26 12:00:00Z]

  setup do
    set_feature_flag(:panl_post_launch, true)
    %{researcher: Factories.insert!(:creator)}
  end

  defp vm(user, assigns \\ %{}),
    do: LicensesModalViewBuilder.view_model(user, Map.put_new(assigns, :now, @now))

  defp item(vm, license), do: Enum.find(vm.items, &(&1.id == license))
  defp draft(license, draft), do: %{draft: %{license => draft}}

  # A system admin with no rows of their own beside the user, so the row can go.
  defp admin_without_features! do
    Mica.Repo.insert!(%Account.User{
      email: "admin2@example.org",
      displayname: "Admin",
      hashed_password: "no-password-set"
    })
  end

  defp delete!(user), do: Mica.Repo.delete!(user)

  describe "the items" do
    test "are Publish and Pay-in", %{researcher: researcher} do
      assert Enum.map(vm(researcher).items, & &1.id) == [:publish, :pay_in]
    end

    test "are Publish only without :panl_post_launch", %{researcher: researcher} do
      set_feature_flag(:panl_post_launch, false)

      assert Enum.map(vm(researcher).items, & &1.id) == [:publish]
    end

    test "show a license that is off", %{researcher: researcher} do
      assert %{on?: false, status: "Off", select: nil, change: :none} =
               item(vm(researcher), :publish)
    end

    test "show a license that is on with its end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})

      assert %{on?: true, status: "On until 26 Nov 2027"} = item(vm(researcher), :publish)
    end

    test "show who gave the license and when", %{researcher: researcher} do
      admin = Factories.insert!(:admin)

      Factories.insert!(:license, %{
        user: researcher,
        granted_by: admin,
        granted_at: ~U[2026-11-20 10:00:00Z]
      })

      assert item(vm(researcher), :publish).note =~ "Given by "
      assert item(vm(researcher), :publish).note =~ "20 Nov 2026"
    end

    test "show a license given by no one as given by the system", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, granted_at: ~U[2026-11-20 10:00:00Z]})

      assert item(vm(researcher), :publish).note == "Given by the system, 20 Nov 2026"
    end

    test "show a license whose giver deleted their account as given by a deleted account",
         %{researcher: researcher} do
      admin = admin_without_features!()
      :ok = License.Public.save(admin, researcher, %{publish: {:on, ~D[2027-11-26]}})

      delete!(admin)

      assert item(vm(researcher), :publish).note =~ "Given by a deleted account, "
    end

    test "show a license switched off by someone who deleted their account",
         %{researcher: researcher} do
      admin = admin_without_features!()
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})
      :ok = License.Public.save(admin, researcher, %{publish: :off})

      delete!(admin)

      assert item(vm(researcher), :publish).note =~ "Switched off by a deleted account, "
    end

    test "show a license past its end date as ended", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-25]})

      assert %{on?: false, status: "Ended on 25 Nov 2026"} = item(vm(researcher), :publish)
    end

    test "show a license as ended from 00:00 the day after its end date, Amsterdam time",
         %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-11-30]})

      assert %{on?: false, status: "Ended on 30 Nov 2026"} =
               item(vm(researcher, %{now: ~U[2026-11-30 23:00:00Z]}), :publish)
    end
  end

  describe "the research institute" do
    test "is named under Pay-in", %{researcher: researcher} do
      admin = Factories.insert!(:admin)
      org = Org.Public.create_node!(["vu_test"], [{:en, "VU"}], [{:en, "Vrije Universiteit"}])
      {:ok, org} = Org.Public.mark_research_institute(org, true, admin)
      :ok = Org.Public.add_member(org, researcher, admin)

      assert %{names: "Research institute: Vrije Universiteit", warning: nil, note: nil} =
               item(vm(researcher), :pay_in).institutes
    end

    test "is warned about under Pay-in when the researcher has none", %{researcher: researcher} do
      assert %{names: nil, warning: "No research institute", note: note} =
               item(vm(researcher), :pay_in).institutes

      assert note =~ "pay-ins are refused"
    end

    test "isn't shown under Publish", %{researcher: researcher} do
      assert item(vm(researcher), :publish).institutes == nil
    end
  end

  describe "the change" do
    test "is :off for a license switched off", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})

      assert item(vm(researcher, draft(:publish, %{on?: false})), :publish).change == :off
    end

    test "is :none for a license on with no new period", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2027-11-26]})

      assert item(vm(researcher), :publish).change == :none
    end

    test "30 days ends 30 days from today", %{researcher: researcher} do
      vm = vm(researcher, draft(:pay_in, %{on?: true, period: :days_30}))
      assert item(vm, :pay_in).change == {:on, ~D[2026-12-26]}
    end

    test "60 days ends 60 days from today", %{researcher: researcher} do
      vm = vm(researcher, draft(:pay_in, %{on?: true, period: :days_60}))
      assert item(vm, :pay_in).change == {:on, ~D[2027-01-25]}
    end

    test "90 days ends 90 days from today", %{researcher: researcher} do
      vm = vm(researcher, draft(:pay_in, %{on?: true, period: :days_90}))
      assert item(vm, :pay_in).change == {:on, ~D[2027-02-24]}
    end

    test "1 year ends a year from today", %{researcher: researcher} do
      vm = vm(researcher, draft(:pay_in, %{on?: true, period: :year_1}))
      assert item(vm, :pay_in).change == {:on, ~D[2027-11-26]}
    end

    test "a custom date in the future is the end date", %{researcher: researcher} do
      vm =
        vm(researcher, draft(:publish, %{on?: true, period: :custom, custom_date: "2027-03-01"}))

      assert item(vm, :publish).change == {:on, ~D[2027-03-01]}
    end

    test "a custom date in the past is refused", %{researcher: researcher} do
      vm =
        vm(researcher, draft(:publish, %{on?: true, period: :custom, custom_date: "2026-11-01"}))

      assert item(vm, :publish).change == {:error, :end_date_not_in_future}
    end

    test "a custom date of today is refused", %{researcher: researcher} do
      vm =
        vm(researcher, draft(:publish, %{on?: true, period: :custom, custom_date: "2026-11-26"}))

      assert item(vm, :publish).change == {:error, :end_date_not_in_future}
    end

    test "no custom date is refused", %{researcher: researcher} do
      vm = vm(researcher, draft(:publish, %{on?: true, period: :custom}))
      assert item(vm, :publish).change == {:error, :no_custom_date}
    end

    test "switching a license on without an end date is refused", %{researcher: researcher} do
      assert item(vm(researcher, draft(:publish, %{on?: true})), :publish).change ==
               {:error, :no_end_date}
    end

    test "giving a license that is on again sets the new end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: ~D[2026-12-01]})

      vm = vm(researcher, draft(:publish, %{period: :year_1}))
      assert item(vm, :publish).change == {:on, ~D[2027-11-26]}
    end
  end

  describe "the errors" do
    test "show only once support tried to save", %{researcher: researcher} do
      assert item(vm(researcher, draft(:publish, %{on?: true})), :publish).error == nil
    end

    test "say what to fix after saving", %{researcher: researcher} do
      assigns = Map.put(draft(:publish, %{on?: true}), :show_errors?, true)

      assert item(vm(researcher, assigns), :publish).error == "Choose when the license ends."
    end
  end

  describe "the end date select" do
    test "lists the four periods and a custom date", %{researcher: researcher} do
      %{select: %{options: options}} =
        item(vm(researcher, draft(:publish, %{on?: true})), :publish)

      assert Enum.map(options, & &1.id) == [:days_30, :days_60, :days_90, :year_1, :custom]
    end

    test "names each period's end date", %{researcher: researcher} do
      %{select: %{options: [days_30 | _]}} =
        item(vm(researcher, draft(:publish, %{on?: true})), :publish)

      assert days_30.label == "30 days, until 26 Dec 2026"
    end
  end
end
