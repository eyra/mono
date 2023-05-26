defmodule CoreWeb.UI.Content do
  use CoreWeb, :html

  import Frameworks.Pixel.Image
  alias Frameworks.Pixel.Text

  attr(:items, :list, required: true)

  def list(assigns) do
    ~H"""
    <div class="flex flex-col gap-10">
      <%= for {item, index} <- Enum.with_index(@items) do %>
        <.item id={Integer.to_string(index)} {item} />
      <% end %>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:path, :string, required: true)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:quick_summary, :string, required: true)
  attr(:tag, :map, default: %{type: nil, text: nil})
  attr(:image, :map, default: %{type: nil, info: nil})

  attr(:title_css, :string,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  attr(:subtitle_css, :string,
    default: "text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"
  )

  def item(assigns) do
    ~H"""
    <Button.Action.redirect to={@path}>
      <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
        <div class="flex flex-row w-full">
          <div class="flex-grow p-4 lg:p-6">
            <!-- SMALL VARIANT -->
            <div class="lg:hidden w-full">
              <div>
                <div class={@title_css}><%= @title %></div>
                <.spacing value="XXS" />
                <div class={@subtitle_css}><%= @subtitle %></div>
                <.spacing value="XXS" />
                <div class="flex flex-row">
                  <div class="flex-wrap">
                    <.tag {Map.put(@tag, :size, "S")} />
                  </div>
                </div>
              </div>
            </div>
            <!-- LARGE VARIANT -->
            <div class="hidden lg:block w-full h-full">
              <div class="flex flex-row w-full h-full gap-4 justify-center">
                <div class="flex-grow">
                  <div class="flex flex-col gap-2 h-full justify-center">
                    <div class={@title_css}><%= @title %></div>
                    <%= if @subtitle do %>
                      <div class={@subtitle_css}><%= @subtitle %></div>
                    <% end %>
                  </div>
                </div>
                <div class="flex-shrink-0 w-40 place-self-center">
                  <Text.label color="text-grey2">
                    <%= @quick_summary %>
                  </Text.label>
                </div>
                <div class="flex-shrink-0 w-30 place-self-center">
                  <.tag {Map.put(@tag, :size, "L")} />
                </div>
              </div>
            </div>
          </div>
          <%= if @image.type == :catalog do %>
            <div class="flex-wrap flex-shrink-0 w-30">
              <.blurhash id={@id} image={@image.info} corners="rounded-br-md rounded-tr-xl md:rounded-tr-md" />
            </div>
          <% end %>
          <%= if @image.type == :avatar do %>
            <div class="flex-wrap flex-shrink-0 my-6 mr-6">
              <img src={@image.info} class="w-20 h-20 rounded-full" alt="">
            </div>
          <% end %>
        </div>
      </div>
    </Button.Action.redirect>
    """
  end

  defp tag_bg_color(type) do
    case type do
      :delete -> "bg-delete"
      :warning -> "bg-warning"
      :success -> "bg-success"
      :primary -> "bg-primary"
      :secondary -> "bg-secondary"
      :tertiary -> "bg-tertiary"
      :disabled -> "bg-grey3"
      type -> "bg-#{type}"
    end
  end

  defp tag_text_color(type) do
    case type do
      :tertiary -> "text-grey1"
      _ -> "text-white"
    end
  end

  defp tag_class(size) do
    case size do
      "S" -> "px-2 py-2px font-caption text-captionsmall md:text-caption"
      _ -> "px-2 py-3px text-caption font-caption"
    end
  end

  attr(:type, :atom, required: true)
  attr(:text, :string, required: true)
  attr(:size, :string, default: "L")

  def tag(%{type: type, size: size} = assigns) do
    bg_color = tag_bg_color(type)
    text_color = tag_text_color(type)
    class = tag_class(size)

    assigns =
      assign(assigns, %{
        bg_color: bg_color,
        text_color: text_color,
        class: class
      })

    ~H"""
    <div class="flex flex-row justify-center">
      <div class={"#{@text_color} flex-wrap rounded-full #{@bg_color} #{@class}"}>
        <%= @text %>
      </div>
    </div>
    """
  end
end
