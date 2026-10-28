defmodule Systems.Paper.System do
  use Core.System

  def oban_queues, do: [ris_import: 1]
end
