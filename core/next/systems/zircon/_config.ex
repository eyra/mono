defmodule Systems.Zircon.Config do
  @moduledoc false

  require Core.Env
  @screening_agent_module Core.Env.compile_env([:zircon, :screening, :agent_module])

  def screening_agent_module, do: @screening_agent_module
end
