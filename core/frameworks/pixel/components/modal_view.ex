defmodule Frameworks.Pixel.ModalView do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  defmacro __using__(_) do
    quote do
      @impl true
      def handle_event("show_modal", modal, socket) do
        {:noreply, socket |> assign(modal: modal)}
      end

      @impl true
      def handle_event("hide_modal", _, socket) do
        {:noreply, socket |> assign(modal: nil)}
      end
    end
  end

  attr(:modal, :map, default: nil)

  @spec dynamic(map()) :: Phoenix.LiveView.Rendered.t()
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

  def container(%{style: style} = assigns) do
    allowed_styles = [:page, :sheet, :dialog, :notification]

    unless style in allowed_styles do
      raise ArgumentError,
            "Invalid style: #{style}. Allowed styles are: #{Enum.join(allowed_styles, ", ")}"
    end

    ~H"""
    <%= if @style == :page do %>
      <.page live_component={@live_component} />
    <% end %>
    <%= if @style == :sheet do %>
      <.sheet live_component={@live_component} />
    <% end %>
    <%= if @style == :dialog do %>
      <.dialog live_component={@live_component} />
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

  def dialog(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <div class="w-[700px] px-4 sm:px-10">
          <div class="relative h-full w-full bg-white pt-6 pb-9 px-9 rounded shadow-floating">
            <%!-- Floating close button --%>
            <div class="absolute z-30 top-6 right-9">
                <.close_button />
            </div>
            <%!-- BODY --%>
            <div class="h-full w-full overflow-y-scroll">
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
          <div class="relative h-full w-full bg-white pt-6 pb-9 px-9 rounded shadow-floating">
            <%!-- Floating close button --%>
            <div class="absolute z-30 top-9 right-9">
                <.close_button />
            </div>
            <%!-- BODY --%>
            <div class="h-full w-full overflow-y-scroll">
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
        id={@live_component.ref.id}
        module={@live_component.ref.module}
        {@live_component.params}
      />
    """
  end
end
