defmodule Systems.Onyx.RISProcessorJob do
  use Oban.Worker, queue: :ris_processor

  alias Systems.Onyx

  @impl true
  def perform(%Oban.Job{args: %{"tool_file_id" => tool_file_id}}) do
    Onyx.RISFile.process(tool_file_id)
    :ok
  end
end
