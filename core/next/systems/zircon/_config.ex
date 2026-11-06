defmodule Next.Systems.Zircon.Config do
  @moduledoc false

  require Mica.Env
  @screening_agent_module Mica.Env.compile_env([:zircon, :screening, :agent_module])

  def screening_agent_module, do: @screening_agent_module
end
