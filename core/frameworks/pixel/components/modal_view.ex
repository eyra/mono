defmodule Frameworks.Pixel.ModalView do
  use CoreWeb, :html

  alias Frameworks.Pixel.Button

  attr(:modal, :map, default: nil)

  def dynamic(assigns) do
    ~H"""
    <div class={"#{if @modal do "block" else "hidden" end}"}>
      <%= if @modal do %>
        <.container {@modal} />
      <% end %>
    </div>
    """
  end

  attr(:style, :atom, required: true)
  attr(:live_component, :map, required: true)

  def container(assigns) do
    ~H"""
    <%= if @style == :page do %>
      <.page live_component={@live_component} />
    <% end %>
    <%= if @style == :sheet do %>
      <.sheet live_component={@live_component} />
    <% end %>
    <%= if @style == :notification do %>
      <.notification live_component={@live_component} />
    <% end %>
    """
  end

  attr(:live_component, :string, required: true)

  def page(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <div class={"w-[960px] p-4 sm:px-10 sm:py-20 h-full"}>
          <div class={"flex flex-col w-full bg-white rounded shadow-floating h-full pt-8 pb-8"}>
            <%!-- HEADER --%>
            <div class="shrink-0 px-8">
              <div class="flex flex-row">
                <div class="flex-grow">
                  <.title live_component={@live_component} />
                </div>
                <.close_button />
              </div>
            </div>
            <%!-- BODY --%>
            <div class="h-full overflow-y-scroll px-8">
              <.body live_component={@live_component} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:live_component, :string, required: true)

  def sheet(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <div class={"w-[960px] p-4 sm:px-10 sm:py-20"}>
          <div class={"flex flex-col w-full bg-white rounded shadow-floating pt-8 pb-8"}>
            <%!-- HEADER --%>
            <div class="shrink-0 px-8">
              <div class="flex flex-row">
                <div class="flex-grow">
                  <.title live_component={@live_component} centered?={true}/>
                </div>
                <.close_button />
              </div>
            </div>
            <%!-- BODY --%>
            <div class="h-full overflow-y-scroll px-8">
              <.body live_component={@live_component} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:live_component, :string, required: true)

  def notification(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <div class="w-[700px] px-4 sm:px-10">
          <div class="flex flex-col h-full w-full bg-white pt-8 pb-8 rounded shadow-floating">
            <%!-- HEADER --%>
            <div class="shrink-0 px-8">
              <div class="flex flex-row">
                <div class="flex-grow">
                  <.title live_component={@live_component} centered?={true}/>
                </div>
                <.close_button />
              </div>
            </div>
            <%!-- BODY --%>
            <div class="h-full overflow-y-scroll px-8 pb-4">
              <.body live_component={@live_component} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr(:live_component, :map, required: true)
  attr(:centered?, :boolean, default: false)

  def title(assigns) do
    ~H"""
      <Text.title2 align={"#{if @centered? do "text-center" else "text-left" end}"}>
        <%= Map.get(@live_component.params, :title) %>
      </Text.title2>
    """
  end

  def close_button(assigns) do
    ~H"""
      <Button.dynamic {
        %{
          action: %{type: :send, event: "hide_modal"},
          face: %{type: :icon, icon: :close}
        }
      } />
    """
  end

  attr(:live_component, :map, required: true)

  def body(assigns) do
    ~H"""
      <.live_component
        id={:modal_view_content}
        module={@live_component.ref.module}
        {@live_component.params}
      />
    """
  end
end
