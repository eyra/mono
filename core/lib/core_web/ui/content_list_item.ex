defmodule CoreWeb.UI.ContentListItem do
  use CoreWeb.UI.Component
  alias Surface.Components.LiveRedirect

  alias Frameworks.Pixel.{Image}
  alias Frameworks.Pixel.Text.{Label}

  alias CoreWeb.UI.ContentTag

  defviewmodel(
    path: nil,
    title: nil,
    subtitle: nil,
    quick_summary: nil,
    tag: [type: nil, text: nil],
    image: [type: nil, info: nil],
    title_css: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1",
    subtitle_css: "text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"
  )

  prop(vm, :map, required: true)

  data(image_info, :any)

  def render(assigns) do
    ~H"""
      <LiveRedirect to={{path(@vm)}} class="block">
        <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
          <div class="flex flex-row w-full">
            <div class="flex-grow p-4 lg:p-6">
              <!-- SMALL VARIANT -->
              <div class="lg:hidden w-full">
                <div>
                  <div class={{title_css(@vm)}}>{{title(@vm)}}</div>
                  <Spacing value="XXS" />
                  <div class={{subtitle_css(@vm)}}>{{subtitle(@vm)}}</div>
                  <Spacing value="XXS" />
                  <div class="flex flex-row">
                    <div class="flex-wrap">
                      <ContentTag vm={{ Map.put(tag(@vm), :size, "S" )}} />
                    </div>
                  </div>
                </div>
              </div>
              <!-- LARGE VARIANT -->
              <div class="hidden lg:block w-full h-full">
                <div class="flex flex-row w-full h-full gap-4 justify-center">
                  <div class="flex-grow">
                    <div class="flex flex-col gap-2 h-full justify-center">
                      <div class={{title_css(@vm)}}>{{title(@vm)}}</div>
                      <div :if={{ has_subtitle?(@vm) }} class={{subtitle_css(@vm)}}>{{subtitle(@vm)}}</div>
                    </div>
                  </div>
                  <div class="flex-shrink-0 w-40 place-self-center">
                    <Label color="text-grey2">
                      {{quick_summary(@vm)}}
                    </Label>
                  </div>
                  <div class="flex-shrink-0 w-30 place-self-center">
                    <ContentTag vm={{ Map.put(tag(@vm), :size, "L" )}} />
                  </div>
                </div>
              </div>
            </div>
            <div :if={{ image_type(@vm) == :catalog }} class="flex-wrap flex-shrink-0 w-30">
              <Image  image={{image_info(@vm)}} corners="rounded-br-md rounded-tr-xl md:rounded-tr-md" />
            </div>
            <div :if={{ image_type(@vm) == :avatar }} class="flex-wrap flex-shrink-0 my-6 mr-6">
              <img src={{image_info(@vm)}} class="w-20 h-20 rounded-full" alt="" />
            </div>
          </div>
        </div>
      </LiveRedirect>
    """
  end
end

defmodule CoreWeb.UI.ContentListItem.Example do
  use Surface.Catalogue.Example,
    subject: CoreWeb.UI.ContentListItem,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Share view",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  data(vm1, :map,
    default: %{
      path: "/",
      title: Faker.Lorem.sentence(3),
      subtitle: Faker.Lorem.sentence(6),
      quick_summary: Faker.Lorem.sentence(4),
      tag: %{type: :tertiary, text: Faker.Lorem.word()}
    }
  )

  data(vm2, :map,
    default: %{
      path: "/",
      title: Faker.Lorem.sentence(5),
      subtitle: Faker.Lorem.sentence(12),
      quick_summary: Faker.Lorem.sentence(4),
      tag: %{type: :delete, text: Faker.Lorem.word()},
      image: %{type: :avatar, info: Core.ImageHelpers.get_photo_url(%{photo_url: nil})}
    }
  )

  data(vm3, :map,
    default: %{
      path: "/",
      title: Faker.Lorem.sentence(16),
      subtitle: Faker.Lorem.sentence(24),
      quick_summary: Faker.Lorem.sentence(4),
      tag: %{type: :success, text: Faker.Lorem.word()},
      image: %{type: :avatar, info: Core.ImageHelpers.get_photo_url(%{photo_url: nil})}
    }
  )

  def render(assigns) do
    image_id = Core.ImageCatalog.Unsplash.random(:abstract)

    ~H"""
    <div class="flex flex-col gap-10">
      <ContentListItem vm={{@vm1 |> Map.put(:image, %{type: :catalog, info: Core.ImageHelpers.get_image_info(image_id, 400, 300) }) }} />
      <ContentListItem vm={{@vm2}} />
      <ContentListItem vm={{@vm3}} />
    </div>
    """
  end
end
