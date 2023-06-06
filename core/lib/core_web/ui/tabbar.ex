defmodule CoreWeb.UI.Tabbar do
  @moduledoc false
  use CoreWeb, :html

  import CoreWeb.UI.FunctionComponent
  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Button

  defp get_tab(:seperated, tab, index), do: Map.merge(tab, %{type: :seperated, index: index})
  defp get_tab(:segmented, tab, _), do: Map.put(tab, :type, :segmented)

  defp gap(:seperated), do: "gap-6"
  defp gap(:segmented), do: "gap-0"

  defp shape(%{size: :wide, type: :segmented}), do: "rounded-full overflow-hidden h-10 bg-grey5"
  defp shape(%{size: :narrow}), do: "w-full"
  defp shape(_), do: ""

  attr(:id, :any, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:tabs, :any, required: true)
  attr(:size, :atom, default: :wide)
  attr(:initial_tab, :any, default: nil)

  def container(assigns) do
    ~H"""
    <div id={@id} data-initial-tab={@initial_tab} phx-hook="Tabbar" class={"#{shape(assigns)}"}>
      <%= if @size == :wide do %>
        <.container_wide type={@type} tabs={@tabs} />
      <% end %>
      <%= if @size == :narrow do %>
        <.container_narrow tabs={@tabs} />
      <% end %>
    </div>
    """
  end

  attr(:type, :atom, default: :seperated)
  attr(:tabs, :any, required: true)

  def container_wide(assigns) do
    ~H"""
    <div id="container_wide" class={"flex flex-row items-center h-full #{gap(@type)}"}>
      <%= for {tab, index} <- Enum.with_index(@tabs) do %>
        <div class="flex-shrink-0 h-full">
          <.item tabbar="wide" opts="" {get_tab(@type, tab, index)} />
        </div>
      <% end %>
    </div>
    """
  end

  attr(:tabs, :any, required: true)

  def container_narrow(assigns) do
    ~H"""
    <div id="container_narrow">
      <div id="tabbar_dropdown" class="absolute z-50 left-0 top-navbar-height w-full h-full hidden">
        <.dropdown tabs={@tabs} />
      </div>
      <div
        id="tabbar_narrow"
        phx-hook="Toggle"
        target="tabbar_dropdown"
        class="flex flex-row cursor-pointer items-center h-full w-full"
      >
        <div class="flex-shrink-0">
          <%= for {tab, index} <- Enum.with_index(@tabs) do %>
            <div class="flex-shrink-0">
              <.item tabbar="narrow" opts="hide-when-idle" {Map.merge(tab, %{index: index})} />
            </div>
          <% end %>
        </div>
        <div class="flex-grow">
        </div>
        <div>
          <img src="/images/icons/dropdown.svg" alt="Show tabbar dropdown">
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  slot(:inner_block, required: true)

  def tab(assigns) do
    ~H"""
    <div id={"tab_#{@id}"} class="hidden">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:tabs, :list, required: true)

  def content(assigns) do
    ~H"""
    <div>
      <div class="h-navbar-height" />
      <%= for tab <- @tabs do %>
        <.tab id={tab.id}>
          <%= if Map.has_key?(tab, :live_component) do %>
            <.live_component id={tab.id} module={tab.live_component} {tab.props} />
          <% else %>
            <.function_component function={tab.function_component} props={tab.props} />
          <% end %>
        </.tab>
      <% end %>
    </div>
    """
  end

  attr(:tabs, :any, required: true)

  def dropdown(assigns) do
    ~H"""
    <div>
      <.line />
      <div class="flex flex-col items-left p-6 gap-6 w-full bg-white drop-shadow-2xl">
        <%= for {tab, index} <- Enum.with_index(@tabs) do %>
          <div class="flex-shrink-0">
            <.item tabbar="dropdown" index={index} {tab} />
          </div>
        <% end %>
      </div>
      <.line />
      <div class="h-5 bg-gradient-to-b from-black opacity-shadow">
      </div>
    </div>
    """
  end

  defp align(%{align: :left}), do: "justify-left"
  defp align(%{align: :center}), do: "justify-center"
  defp align(%{type: :sheet}), do: "justify-center"
  defp align(_), do: "justify-left"

  defp combine_shifted(tabs) do
    tabs |> Enum.chunk_every(2, 1, [%{id: "fake_tab"}])
  end

  attr(:tabs, :any, required: true)
  slot(:inner_block)

  def footer(assigns) do
    ~H"""
    <Area.content class="mb-8">
      <Margin.y id={:page_top} />
      <%= for {[tab1, tab2], index} <- Enum.with_index(combine_shifted(@tabs)) do %>
        <Area.dynamic type={tab1.type} >
          <div class={"flex flex-row #{align(tab1)}"}>
            <div
              id={"tabbar-footer-item-#{tab1.id}"}
              phx-hook="TabbarFooterItem"
              data-tab-id={tab1.id}
              data-target-tab-id={tab2.id}
              class="tabbar-footer-item cursor-pointer hidden"
            >
              <%= if index < Enum.count(@tabs) - 1 do %>
                <Button.Face.plain_icon label={tab2.forward_title} icon={:forward} />
              <% else %>
                <%= render_slot(@inner_block) %>
              <% end %>
            </div>
          </div>
        </Area.dynamic>
      <% end %>
    </Area.content>
    """
  end

  def center_correction_for_number(1), do: "mr-1px"
  def center_correction_for_number(4), do: "mr-1px"
  def center_correction_for_number(_), do: ""

  def icon_text(_, false, true, _), do: "!"
  def icon_text(_, _, _, count) when not is_nil(count), do: "#{count}"
  def icon_text(index, _, _, _), do: index + 1

  def active_icon(_), do: "bg-primary text-white"

  def idle_icon(false, true), do: "bg-warning text-white"
  def idle_icon(_, _), do: "bg-grey5 text-grey2"

  def active_title(:segmented), do: "text-white"
  def active_title(_), do: "text-primary"

  def idle_title(false, true), do: "text-warning"
  def idle_title(_, _), do: "text-grey2"

  def idle_shape("wide", :segmented, false, true), do: "h-full px-4 bg-warning"
  def idle_shape("wide", :segmented, _, _), do: "h-full px-4 bg-grey5"
  def idle_shape(_, _, _, _), do: "rounded-full"

  def active_shape(_, :segmented), do: "h-full px-4 bg-primary"
  def active_shape(_, _), do: "rounded-full"

  def title_inset(:segmented), do: "mt-0"
  def title_inset(_), do: "mt-1px"

  attr(:tabbar, :string, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:id, :string)
  attr(:title, :string)
  attr(:ready, :boolean, default: true)
  attr(:show_errors, :boolean, default: false)
  attr(:count, :integer, default: nil)
  attr(:index, :integer, default: nil)
  attr(:opts, :string, default: "")

  def item(assigns) do
    ~H"""
    <div
      id={"tabbar-#{@tabbar}-#{@id}"}
      data-tab-id={@id}
      phx-hook="TabbarItem"
      class={"tabbar-item flex flex-row items-center justify-start focus:outline-none cursor-pointer #{@opts} #{idle_shape(@tabbar, @type, @ready, @show_errors)}"}
      idle-class={idle_shape(@tabbar, @type, @ready, @show_errors)}
      active-class={active_shape(@tabbar, @type)}
    >
      <%= if @index do %>
        <div
          class={"icon w-6 h-6 font-caption text-caption rounded-full flex items-center #{idle_icon(@ready, @show_errors)}"}
          idle-class={idle_icon(@ready, @show_errors)}
          active-class={active_icon(@type)}
        >
          <span class={"text-center w-full mt-1px #{center_correction_for_number(icon_text(@index, @ready, @show_errors, @count))}"}><%= icon_text(@index, @ready, @show_errors, @count) %></span>
        </div>
      <% end %>

      <%= if @title && @index do %>
        <div class="ml-3" />
      <% end %>

      <%= if @title do %>
        <div class="flex flex-col items-center justify-center">
          <div
            class={"title text-button font-button #{title_inset(@type)} #{idle_title(@ready, @show_errors)}"}
            idle-class={idle_title(@ready, @show_errors)}
            active-class={active_title(@type)}
          >
            <%= @title %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
