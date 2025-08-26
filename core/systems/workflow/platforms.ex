defmodule Systems.Workflow.Platforms do
  @moduledoc """
  Defines DDP platforms that are supported out of the box.
  Make sure to add icons for each platform in the `priv/static/images/icons` directory:
  * <platform>.svg
  * <platform>_square.svg
  See Figma https://www.figma.com/design/RXKuvMFGz3Eln5MNPJ1q6a/Design-system?node-id=470-10741&t=XxCVZd4kNTsfcQP7-1 for reference.
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
         :snapchat,
         :spotify,
         :tiktok,
         :whatsapp,
         :x,
         :youtube
       ]}
end
