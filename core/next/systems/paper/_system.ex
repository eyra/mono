defmodule Systems.Paper.System do
  use Core.System

  def children, do: [{Registry, keys: :unique, name: Systems.Paper.RISProcessorRegistry}]

  def oban_queues, do: [ris_import: 1]
end
