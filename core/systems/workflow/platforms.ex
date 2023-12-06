defmodule Systems.Workflow.Platforms do
  @moduledoc """
  Defines DDP platforms that are supported out of the box.
  """
  use Core.Enums.Base,
      {:platforms,
       [
         :apple,
         :facebook,
         :google,
         :instagram,
         :netflix,
         :samsung,
         :tiktok,
         :whatsapp,
         :x,
         :youtube
       ]}
end
