defmodule Systems.License.PublicTest do
  use Mica.DataCase, async: false
  use Mica.FeatureFlags.Test

  import Frameworks.Signal.TestHelper

  alias Systems.Content
  alias Systems.License

  @today ~D[2026-11-26]

  setup do
    set_feature_flag(:panl_post_launch, true)

    %{
      admin: Factories.insert!(:admin, %{email: "admin1@example.org"}),
      researcher: Factories.insert!(:creator)
    }
  end

  defp current(user, license), do: License.Public.get_current(user, license)

  describe "end_date/2" do
    test "30 days" do
      assert License.Public.end_date(:days_30, @today) == ~D[2026-12-26]
    end

    test "60 days" do
      assert License.Public.end_date(:days_60, @today) == ~D[2027-01-25]
    end

    test "90 days" do
      assert License.Public.end_date(:days_90, @today) == ~D[2027-02-24]
    end

    test "1 year" do
      assert License.Public.end_date(:year_1, @today) == ~D[2027-11-26]
    end

    test "1 year from 29 February ends on 28 February" do
      assert License.Public.end_date(:year_1, ~D[2028-02-29]) == ~D[2029-02-28]
    end
  end

  describe "licenses/0" do
    test "has Publish and Pay-in with :panl_post_launch" do
      assert License.Public.licenses() == [:publish, :pay_in]
    end

    test "has only Publish without :panl_post_launch" do
      set_feature_flag(:panl_post_launch, false)
      assert License.Public.licenses() == [:publish]
    end
  end

  describe "save/4" do
    test "gives Pay-in for 1 year and records the end date, who and when",
         %{admin: admin, researcher: researcher} do
      end_date = License.Public.end_date(:year_1)

      assert :ok = License.Public.save(admin, researcher, %{pay_in: {:on, end_date}})

      assert %License.Model{
               license: :pay_in,
               valid_until: ^end_date,
               granted_by_id: granted_by_id,
               granted_at: %DateTime{} = granted_at,
               revoked_at: nil
             } = current(researcher, :pay_in)

      assert granted_by_id == admin.id
      assert DateTime.diff(DateTime.utc_now(), granted_at) < 60
      assert License.Public.active?(researcher, :pay_in)
    end

    test "gives Publish and Pay-in in one save", %{admin: admin, researcher: researcher} do
      end_date = License.Public.end_date(:days_90)

      assert :ok =
               License.Public.save(admin, researcher, %{
                 publish: {:on, end_date},
                 pay_in: {:on, end_date}
               })

      assert License.Public.active?(researcher, :publish)
      assert License.Public.active?(researcher, :pay_in)
    end

    test "gives both licenses to a researcher outside any research institute",
         %{admin: admin, researcher: researcher} do
      end_date = License.Public.end_date(:year_1)

      assert [] = Systems.Org.Public.list_research_institutes(researcher)

      assert :ok =
               License.Public.save(admin, researcher, %{
                 publish: {:on, end_date},
                 pay_in: {:on, end_date}
               })

      assert License.Public.active?(researcher, :publish)
      assert License.Public.active?(researcher, :pay_in)
    end

    test "records a custom end date in the future", %{admin: admin, researcher: researcher} do
      end_date = Date.add(Date.utc_today(), 17)

      assert :ok = License.Public.save(admin, researcher, %{publish: {:on, end_date}})

      assert %{valid_until: ^end_date} = current(researcher, :publish)
    end

    test "refuses an end date of today", %{admin: admin, researcher: researcher} do
      assert {:error, {:end_date_not_in_future, :publish}} =
               License.Public.save(admin, researcher, %{publish: {:on, Date.utc_today()}})

      assert current(researcher, :publish) == nil
    end

    test "refuses an end date in the past", %{admin: admin, researcher: researcher} do
      past = Date.add(Date.utc_today(), -3)

      assert {:error, {:end_date_not_in_future, :publish}} =
               License.Public.save(admin, researcher, %{publish: {:on, past}})

      assert current(researcher, :publish) == nil
    end

    test "saves nothing when one of the changes is refused",
         %{admin: admin, researcher: researcher} do
      assert {:error, {:end_date_not_in_future, :pay_in}} =
               License.Public.save(admin, researcher, %{
                 publish: {:on, License.Public.end_date(:year_1)},
                 pay_in: {:on, Date.utc_today()}
               })

      assert current(researcher, :publish) == nil
    end

    test "refuses a user who isn't a system admin", %{researcher: researcher} do
      other = Factories.insert!(:creator)

      assert {:error, :forbidden} =
               License.Public.save(other, researcher, %{
                 publish: {:on, License.Public.end_date(:year_1)}
               })

      assert current(researcher, :publish) == nil
    end

    test "refuses the researcher giving themselves a license", %{researcher: researcher} do
      assert {:error, :forbidden} =
               License.Public.save(researcher, researcher, %{
                 pay_in: {:on, License.Public.end_date(:year_1)}
               })

      assert current(researcher, :pay_in) == nil
    end

    test "refuses Pay-in without :panl_post_launch", %{admin: admin, researcher: researcher} do
      set_feature_flag(:panl_post_launch, false)

      assert {:error, {:unknown_license, :pay_in}} =
               License.Public.save(admin, researcher, %{
                 pay_in: {:on, License.Public.end_date(:year_1)}
               })

      assert current(researcher, :pay_in) == nil
    end

    test "switching off records who and when and keeps the record",
         %{admin: admin, researcher: researcher} do
      :ok =
        License.Public.save(admin, researcher, %{publish: {:on, License.Public.end_date(:year_1)}})

      assert :ok = License.Public.save(admin, researcher, %{publish: :off})

      assert %{
               revoked_by_id: revoked_by_id,
               revoked_at: %DateTime{},
               granted_by_id: granted_by_id
             } =
               current(researcher, :publish)

      assert revoked_by_id == admin.id
      assert granted_by_id == admin.id
      refute License.Public.active?(researcher, :publish)
    end

    test "switching off a license that isn't on adds nothing",
         %{admin: admin, researcher: researcher} do
      assert :ok = License.Public.save(admin, researcher, %{pay_in: :off})

      assert License.Public.list_records(researcher) == []
    end

    test "giving a license again sets the new end date and keeps the earlier record",
         %{admin: admin, researcher: researcher} do
      :ok =
        License.Public.save(admin, researcher, %{
          publish: {:on, License.Public.end_date(:days_30)}
        })

      new_end_date = License.Public.end_date(:year_1)
      :ok = License.Public.save(admin, researcher, %{publish: {:on, new_end_date}})

      assert %{valid_until: ^new_end_date} = current(researcher, :publish)
      assert length(License.Public.list_records(researcher)) == 2
    end

    test "giving a license again after switching it off turns it on",
         %{admin: admin, researcher: researcher} do
      :ok =
        License.Public.save(admin, researcher, %{
          publish: {:on, License.Public.end_date(:days_30)}
        })

      :ok = License.Public.save(admin, researcher, %{publish: :off})

      :ok =
        License.Public.save(admin, researcher, %{
          publish: {:on, License.Public.end_date(:days_60)}
        })

      assert License.Public.active?(researcher, :publish)
    end

    test "dispatches {:license, :updated}", %{admin: admin, researcher: researcher} do
      isolate_signals()

      :ok =
        License.Public.save(admin, researcher, %{publish: {:on, License.Public.end_date(:year_1)}})

      assert_signal_dispatched({:license, :updated})
    end
  end

  describe "active?/3" do
    test "counts on its end date", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: @today})

      assert License.Public.active?(researcher, :publish, @today)
    end

    test "is off the day after its end date, without anyone acting", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: @today})

      refute License.Public.active?(researcher, :publish, Date.add(@today, 1))
    end

    test "is off for a user who never had it", %{researcher: researcher} do
      refute License.Public.active?(researcher, :publish)
    end

    test "Publish doesn't count as Pay-in", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, license: :publish})

      refute License.Public.active?(researcher, :pay_in)
    end
  end

  describe "list_user_ids/2" do
    test "has the users whose license counts on the day", %{researcher: researcher} do
      ended = Factories.insert!(:creator)
      Factories.insert!(:license, %{user: researcher, valid_until: Date.add(@today, 1)})
      Factories.insert!(:license, %{user: ended, valid_until: Date.add(@today, -1)})

      assert License.Public.list_user_ids(:publish, @today) == [researcher.id]
    end

    test "reads only the newest record", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        granted_at: ~U[2026-01-01 10:00:00Z],
        valid_until: Date.add(@today, 30)
      })

      Factories.insert!(:license, %{
        user: researcher,
        granted_at: ~U[2026-02-01 10:00:00Z],
        valid_until: Date.add(@today, 30),
        revoked_at: ~U[2026-03-01 10:00:00Z]
      })

      assert License.Public.list_user_ids(:publish, @today) == []
    end
  end

  # The publish check reads the Publish license.
  describe "Content.Private.can_user_publish?/1" do
    test "a creator with a Publish license can publish", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher})

      assert Content.Private.can_user_publish?(researcher)
    end

    test "a creator without a Publish license can't publish", %{researcher: researcher} do
      refute Content.Private.can_user_publish?(researcher)
    end

    test "Pay-in alone doesn't allow publishing", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, license: :pay_in})

      refute Content.Private.can_user_publish?(researcher)
    end

    test "a Publish license past its end date doesn't", %{researcher: researcher} do
      Factories.insert!(:license, %{user: researcher, valid_until: Date.add(Date.utc_today(), -1)})

      refute Content.Private.can_user_publish?(researcher)
    end

    test "a Publish license switched off doesn't", %{researcher: researcher} do
      Factories.insert!(:license, %{
        user: researcher,
        revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      refute Content.Private.can_user_publish?(researcher)
    end
  end
end
