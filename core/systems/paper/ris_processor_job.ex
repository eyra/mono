defmodule Systems.Paper.RISProcessorJob do
  use Oban.Worker, queue: :ris_processor

  alias Systems.Paper

  @impl true
  def perform(%Oban.Job{args: %{"reference_file_id" => reference_file_id}}) do
    Paper.RISFile.process(reference_file_id)
  end
end
