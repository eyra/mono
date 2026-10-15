defmodule Systems.Zircon.Config do
  @moduledoc false

  @screening_agent_module Application.compile_env(:core, [:zircon, :screening, :agent_module])

  def screening_agent_module, do: @screening_agent_module
end
