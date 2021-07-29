defmodule CoreWeb.Devices do
  @moduledoc """
  """
  use Surface.Component

  prop(devices, :any, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~H"""
      <div class="bottom-0 right-0 text-grey1">
        <div class="flex flex-col sm:flex-row justify-center items-center ml-4 h-full">
          <div class="text-title6 font-title6 sm:mr-4 mb-4 sm:mb-0">
            {{@label}}
          </div>
          <div class="flex">
            <div class="mr-4" :for={{ device <- @devices }}>
                <img src={{ "/images/#{device}.svg" }} />
            </div>
          </div>
        </div>
      </div>
    """
  end
end
