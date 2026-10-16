defmodule Systems.Pool.ParticipantsViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Factories
  alias Systems.Fund
  alias Systems.Pool

  setup do
    org =
      Factories.insert!(:org_node, %{
        identifier: ["pool_participants_test_#{System.unique_integer([:positive])}"]
      })

    currency =
      Fund.Factories.create_currency(
        "pool_participants_cur_#{System.unique_integer([:positive])}",
        :legal,
        "ƒ",
        2
      )

    pool =
      Pool.Public.create!(
        "pool_participants_pool_#{System.unique_integer([:positive])}",
        500,
        currency,
        org,
        :citizen
      )

    %{pool: pool}
  end

  describe "view_model/2 baseline" do
    test "returns the standard view-model keys", %{pool: pool} do
      vm = Pool.ParticipantsViewBuilder.view_model(pool, %{})

      assert is_binary(vm.title)
      assert is_list(vm.people)
      assert is_integer(vm.participant_count)
      assert is_binary(vm.search_placeholder)
      assert vm.query_string == ""
    end

    test "is empty when the pool has no participants", %{pool: pool} do
      vm = Pool.ParticipantsViewBuilder.view_model(pool, %{})
      assert vm.people == []
      assert vm.participant_count == 0
    end
  end

  describe "view_model/2 with participants" do
    setup %{pool: pool} do
      activated = Factories.insert!(:member, %{email: "activated@example.com"})

      pre_launch =
        Factories.insert!(:member, %{email: "prelaunch@example.com", confirmed_at: nil})

      Pool.Public.add_participant!(pool, activated)
      Pool.Public.add_participant!(pool, pre_launch)

      %{activated: activated, pre_launch: pre_launch}
    end

    test "lists both participants with the joined-on date",
         %{pool: pool, activated: activated, pre_launch: pre_launch} do
      vm = Pool.ParticipantsViewBuilder.view_model(pool, %{})

      assert vm.participant_count == 2
      emails = Enum.map(vm.people, & &1.email)
      assert activated.email in emails
      assert pre_launch.email in emails

      assert Enum.all?(vm.people, fn p ->
               p.info =~ dgettext("eyra-pool", "participants.added.label")
             end)
    end

    test "narrows the list when query matches one email",
         %{pool: pool, activated: activated} do
      vm = Pool.ParticipantsViewBuilder.view_model(pool, %{query: ["activated"]})

      emails = Enum.map(vm.people, & &1.email)
      assert activated.email in emails
      assert vm.participant_count == 1
    end
  end
end
