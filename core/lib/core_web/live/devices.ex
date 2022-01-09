defmodule CoreWeb.Devices do
  @moduledoc """
  """
  use CoreWeb.UI.Component

  prop(devices, :any, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~F"""
    <div :if={@devices} class="text-grey1">
        <div class="flex flex-row items-center gap-2 h-full">
          <div class="text-title6 font-title6 mr-2">
            {@label}
          </div>
          <div :for={device <- @devices}>
              <img src={"/images/#{device}.svg"} alt={"Select #{device}"} />
          </div>
        </div>
      </div>
    """
  end
end
