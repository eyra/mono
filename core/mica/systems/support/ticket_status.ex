defmodule Systems.Support.TicketStatus do
  @moduledoc """
    Ticket status values.
  """
  use Mica.Enums.Base, {:ticket_status, [:open, :closed]}
end
