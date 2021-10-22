defmodule CoreWeb.Languages do
  @moduledoc """
  """
  use CoreWeb.UI.Component

  prop(languages, :any, required: true)
  prop(label, :string, required: true)

  def render(assigns) do
    ~H"""
    <div class="text-grey1"
        :if={{@languages}}>
        <div class="flex flex-row items-center gap-3 h-full">
          <div class="text-title6 font-title6 mr-1">
            {{@label}}
          </div>
            <div class="" :for={{ language <- @languages }}>
                <img src={{ "/images/icons/#{language}.svg" }} alt="{{language}}" />
            </div>
        </div>
      </div>
    """
  end
end
