defmodule Core.NextActions.Live.NextAction do
  use Surface.Component
  alias Surface.Components.LiveRedirect

  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(cta, :string, required: true)
  prop(url, :string, required: true)
  prop(highlighted, :boolean, default: false)

  def render(assigns) do
    ~H"""
    <LiveRedirect to={{@url}} class="block mb-4">
      <div class={{"p-6", "flex", "items-center", "space-x-4", "rounded-md", "bg-tertiary": @highlighted, "bg-grey5": not @highlighted}}>
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
        <div class="inline-block sm:hidden self-start">
          <svg width="8" height="13" viewBox="0 0 8 13" class={{"fill-current", "text-primary": not @highlighted}}>
            <path d="M0.263916 11.34L4.84392 6.75L0.263916 2.16L1.67392 0.75L7.67392 6.75L1.67392 12.75L0.263916 11.34Z" />
          </svg>
        </div>
      </div>
    </LiveRedirect>
    """
  end
end
