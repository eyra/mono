defmodule Systems.Workflow.Platforms do
  @moduledoc """
  Defines DDP platforms that are supported out of the box.
  """
  use Core.Enums.Base,
      {:platforms,
       [
         :facebook,
         :instagram,
         :tiktok,
         :x,
         :google,
         :youtube,
         :whatsapp,
         :apple,
         :samsung
       ]}
end
