defmodule Systems.Support.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Systems.Support.Public

  describe "list_open_tickets/0" do
    test "return open tickets" do
      ticket = Factories.insert!(:helpdesk_ticket)
      assert Public.list_tickets(:open) == [ticket]
    end

    test "don't return closed tickets" do
      Factories.insert!(:helpdesk_ticket, %{
        completed_at: Faker.DateTime.backward(10) |> DateTime.truncate(:second)
      })

      assert Public.list_tickets(:open) == []
    end
  end

  describe "close_ticket_by_id/1" do
    test "close a ticket via it's id" do
      ticket = Factories.insert!(:helpdesk_ticket)
      Public.close_ticket_by_id(ticket.id)

      assert Public.list_tickets(:open) == []
    end
  end

  describe "create_ticket/2" do
    test "associate the ticket with the user" do
      member = Factories.insert!(:member)

      {:ok, ticket} =
        Public.create_ticket(member, %{
          title: Faker.Lorem.sentence(),
          description: Faker.Lorem.sentence(),
          type: :question
        })

      assert ticket.user.id == member.id
    end
  end
end
