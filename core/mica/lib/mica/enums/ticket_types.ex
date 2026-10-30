defmodule Mica.Enums.TicketTypes do
  @moduledoc """
  Defines the different types of support tickets.
  """
  use Mica.Enums.Base, {:ticket_types, [:question, :bug, :tip]}
end
