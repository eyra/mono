defmodule Systems.Zircon.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Zircon

  def intercept(
        {:paper_reference_file, :updated} = signal,
        %{paper_reference_file: reference_file} = message
      ) do
    tool = Zircon.Public.get_screening_tool_by_reference_file!(reference_file)

    dispatch!(
      {:zircon_screening_tool, signal},
      Map.merge(message, %{zircon_screening_tool: tool})
    )

    :ok
  end
end
