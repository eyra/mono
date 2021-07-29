defmodule CoreWeb.Components.ContentListItem do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias EyraUI.Image
  alias Core.ImageHelpers

  prop(to, :string, required: true)
  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(quick_summary, :string, required: true)
  prop(status, :any, required: true)
  prop(image_id, :any, required: true)

  data(image_info, :any)

  def render(assigns) do
    assigns =
      assigns
      |> Map.put(:image_info, ImageHelpers.get_image_info(assigns.image_id, 96, 96))

    ~H"""
      <LiveRedirect to={{@to}} class="block my-2">
        <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">

          <div class="flex-grow p-4 pr-0 overflow-hidden flex flex-col place-self-center">
            <div class="text-l font-bold mb-1 overflow-ellipsis overflow-hidden">
              {{@title}}
            </div>
            <div class="text-sm overflow-ellipsis overflow-hidden">
              {{@description}}
            </div>
          </div>
          <div class="hidden md:block flex-shrink-0 place-self-center">
            <div class={{"bg-#{@status.color}", "text-white", "text-center", "p-2", "rounded-full", "font-bold", "whitespace-nowrap", "text-xs"}}>
              {{@status.label}}
            </div>
          </div>
          <div class="hidden md:block font-bold text-xs flex-shrink-0 place-self-center">
            {{@quick_summary}}
          </div>
          <div class="w-16 relative flex-shrink-0 md:w-24">
            <Image image={{@image_info}}
                   corners="rounded-br-md rounded-tr-xl md:rounded-tr-md"/>
            <svg xmlns="http://www.w3.org/2000/svg" class="absolute right-0 top-0 block; rounded-tr-md md:hidden" style="width: 32px; height: 32px">
              <polygon points="0, 0 32,0 32, 32" class={{"fill-current", "text-#{@status.color}" }} />
            </svg>
            <div class="absolute right-1 top-0 text-sm md:hidden">
              h
            </div>
          </div>
        </div>
      </LiveRedirect>
    """
  end
end
