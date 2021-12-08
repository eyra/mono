defmodule Systems.Support.TicketStatus do
  @moduledoc """
    Ticket status values.
  """
  use Core.Enums.Base, {:ticket_status, [:open, :closed]}
end
