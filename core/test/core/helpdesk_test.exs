defmodule Core.HelpdeskTest do
  use Core.DataCase

  alias Core.Factories
  alias Core.Helpdesk

  describe "list_open_tickets/0" do
    test "return open tickets" do
      ticket = Factories.insert!(:helpdesk_ticket)
      assert Helpdesk.list_open_tickets() == [ticket]
    end

    test "don't return closed tickets" do
      Factories.insert!(:helpdesk_ticket, %{
        completed_at: Faker.DateTime.backward(10) |> DateTime.truncate(:second)
      })

      assert Helpdesk.list_open_tickets() == []
    end
  end

  describe "close_ticket_by_id/1" do
    test "close a ticket via it's id" do
      ticket = Factories.insert!(:helpdesk_ticket)
      Helpdesk.close_ticket_by_id(ticket.id)

      assert Helpdesk.list_open_tickets() == []
    end
  end

  describe "create_ticket/2" do
    test "associate the ticket with the user" do
      member = Factories.insert!(:member)

      {:ok, ticket} =
        Helpdesk.create_ticket(member, %{
          title: Faker.Lorem.sentence(),
          description: Faker.Lorem.sentence()
        })

      assert ticket.user.id == member.id
    end
  end

  describe "new_ticket_changeset/1" do
    test "associate the ticket with the user" do
      changeset =
        Helpdesk.new_ticket_changeset(%{
          member: Factories.build(:member),
          title: Faker.Lorem.sentence(),
          description: Faker.Lorem.sentence()
        })

      assert changeset.valid?
    end
  end
end
