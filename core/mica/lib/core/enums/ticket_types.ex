defmodule Core.Enums.TicketTypes do
  @moduledoc """
  Defines the different types of support tickets.
  """
  use Core.Enums.Base, {:ticket_types, [:question, :bug, :tip]}
end
