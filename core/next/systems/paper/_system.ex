defmodule Next.Systems.Paper.System do
  use Mica.System

  def oban_queues, do: [ris_import: 1]
end
