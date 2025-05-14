defmodule Systems.Zircon.Switch do
  use Frameworks.Signal.Handler

  alias Systems.Zircon

  def intercept(
        {:paper_reference_file, :updated},
        %{paper_reference_file: paper_reference_file}
      ) do
    zircon_screening_tool =
      Zircon.Public.get_screening_tool_by_reference_file!(paper_reference_file)

    {:continue, :zircon_screening_tool, zircon_screening_tool}
  end
end
