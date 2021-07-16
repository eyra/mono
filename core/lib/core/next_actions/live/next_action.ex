defmodule Core.NextActions.Live.NextAction do
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(cta, :string, required: true)
  prop(url, :string, required: true)

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{@url}} class="block mb-4">
      <div class="bg-tertiary p-6 flex items-center space-x-4 rounded-md">
        <img src="https://www.tamaraday.com/wp-content/uploads/2019/07/Icon-Placeholder.png"
             class="inline-block w-12 h-12">
        <div class="flex-grow">
          <div class="text-xl font-bold">
            {{@title}}
          </div>
          <div>
            {{@description}}
          </div>
        </div>
        <div class="hidden sm:block bg-black text-white text-center p-3 rounded-md font-bold whitespace-nowrap">
          {{@cta}}
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
