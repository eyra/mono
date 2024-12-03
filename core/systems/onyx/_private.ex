defmodule Systems.Onyx.Private do
  alias Systems.Onyx

  def start_processing_ris_file(tool_file_id) when is_integer(tool_file_id) do
    %{"tool_file_id" => tool_file_id}
    |> Onyx.RISProcessorJob.new()
    |> Oban.insert()
  end
end
