defmodule Frameworks.Pixel.Tabbed do
  @moduledoc false
  use CoreWeb, :pixel

  import CoreWeb.UI.FunctionComponent
  import Frameworks.Pixel.Line
  alias Frameworks.Pixel.Button

  defp get_tab(:seperated, tab, index), do: Map.merge(tab, %{type: :seperated, index: index})
  defp get_tab(:segmented, tab, _), do: Map.put(tab, :type, :segmented)

  defp gap(:seperated), do: "gap-6"
  defp gap(:segmented), do: "gap-0"

  defp shape(%{size: :wide, type: :segmented}), do: "rounded-full overflow-hidden h-10 bg-grey5"

  defp shape(%{size: :full, type: :segmented}),
    do: "rounded-full overflow-hidden h-10 w-full bg-grey5"

  defp shape(%{size: :narrow}), do: "w-full"
  defp shape(_), do: ""

  attr(:id, :any, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:tabs, :any, required: true)
  attr(:size, :atom, default: :wide)
  attr(:initial_tab, :any, default: nil)
  attr(:preserve_tab_in_url, :boolean, default: false)

  def bar(assigns) do
    string_preserve_tab = if assigns.preserve_tab_in_url, do: "true", else: "false"

    ~H"""
      <div id={@id} data-initial-tab={@initial_tab} data-="true" data-preserve-tab-in-url={string_preserve_tab} phx-hook="TabBar" class={"#{shape(assigns)}"}>
        <%= if @size == :full do %>
          <.bar_full id={@id} type={@type} tabs={@tabs} />
        <% end %>
        <%= if @size == :wide do %>
          <.bar_wide id={@id} type={@type} tabs={@tabs} />
        <% end %>
        <%= if @size == :narrow do %>
          <.bar_narrow id={@id} tabs={@tabs} />
        <% end %>
      </div>
    """
  end

  attr(:id, :any, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:tabs, :any, required: true)

  def bar_wide(assigns) do
    ~H"""
    <div id="tab_bar_wide" class={"flex flex-row items-center h-full #{gap(@type)}"}>
      <%= for {tab, index} <- Enum.with_index(@tabs) do %>
        <div class="flex-shrink-0 h-full">
          <.tab bar_id={@id} size="wide" opts="" {get_tab(@type, tab, index)} />
        </div>
      <% end %>
    </div>
    """
  end

  attr(:id, :any, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:tabs, :any, required: true)

  def bar_full(assigns) do
    ~H"""
    <div id="tab_bar_full" class={"flex flex-row items-center h-full w-full #{gap(@type)}"}>
      <div class="flex flex-row h-full w-full">
        <%= for {tab, index} <- Enum.with_index(@tabs) do %>
          <div class="flex-1 h-full">
            <.tab bar_id={@id} size="full" opts="" {get_tab(@type, tab, index)} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:id, :any, required: true)
  attr(:tabs, :any, required: true)

  def bar_narrow(assigns) do
    ~H"""
    <div id="tab_bar_narrow">
      <div id="tab_bar_dropdown" class="absolute z-50 left-0 top-navbar-height w-full h-full hidden">
        <.dropdown bar_id={@id} tabs={@tabs} />
      </div>
      <div
        id="tabbar_narrow"
        phx-hook="Toggle"
        target="tab_bar_dropdown"
        class="flex flex-row cursor-pointer items-center h-full w-full"
      >
        <div class="flex-shrink-0 pointer-events-none">
          <%= for {tab, index} <- Enum.with_index(@tabs) do %>
            <div class="flex-shrink-0">
              <.tab bar_id={@id} size="narrow" opts="hide-when-idle" {Map.merge(tab, %{index: index})} />
            </div>
          <% end %>
        </div>
        <div class="flex-grow pointer-events-none">
        </div>
        <div class="pointer-events-none">
          <img src={~p"/images/icons/dropdown.svg"} alt="Show tabbar dropdown">
        </div>
      </div>
    </div>
    """
  end

  attr(:tabs, :list, required: true)
  attr(:include_top_margin, :boolean, default: true)

  def content(assigns) do
    ~H"""
    <div id="tab_content" phx-hook="TabContent">
      <%= if @include_top_margin do %>
        <div class="hidden md:block h-navbar-height" />
        <div class="h-navbar-height" />
      <% end %>
      <%= for tab <- @tabs do %>
        <.panel tab_id={tab.id}>
          <%= if Map.has_key?(tab, :live_component) do %>
            <.live_component id={tab.id} module={tab.live_component} {tab.props} />
          <% end %>
          <%= if Map.has_key?(tab, :child) do %>
            <.live_component {Map.from_struct(tab.child.ref)} {tab.child.params} />
          <% end %>
          <%= if Map.has_key?(tab, :function_component) do %>
            <.function_component function={tab.function_component} props={tab.props} />
          <% end %>
        </.panel>
      <% end %>
    </div>
    """
  end

  attr(:tab_id, :string, required: true)
  slot(:inner_block, required: true)

  def panel(assigns) do
    ~H"""
    <div id={"tab_panel_#{@tab_id}"} data-tab-id={@tab_id} class="tab-panel hidden">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:bar_id, :any, required: true)
  attr(:tabs, :any, required: true)

  def dropdown(assigns) do
    ~H"""
    <div>
      <.line />
      <div class="flex flex-col items-left p-6 gap-6 w-full bg-white drop-shadow-2xl">
        <%= for {tab, index} <- Enum.with_index(@tabs) do %>
          <div class="flex-shrink-0">
            <.tab bar_id={@bar_id} size="dropdown" index={index} {tab} />
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
              id={"tab-footer-item-#{tab1.id}"}
              phx-hook="TabFooterItem"
              data-tab-id={tab1.id}
              data-target-tab-id={tab2.id}
              class="tab-footer-item cursor-pointer hidden"
            >
              <%= if index < Enum.count(@tabs) - 1 do %>
                <Button.Face.plain_icon label={tab2.forward_title} icon={:forward} />
              <% end %>
            </div>
          </div>
        </Area.dynamic>
      <% end %>
    </Area.content>
    <%= render_slot(@inner_block) %>
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
  def idle_shape("full", :segmented, false, true), do: "h-full bg-warning"
  def idle_shape("full", :segmented, _, _), do: "h-full bg-grey5"
  def idle_shape(_, _, _, _), do: "rounded-full"

  def active_shape("full", :segmented), do: "h-full bg-primary"
  def active_shape(_, :segmented), do: "h-full px-4 bg-primary"
  def active_shape(_, _), do: "rounded-full"

  def title_shape("dropdown", _), do: ""
  def title_shape(_, _), do: "w-full items-center"

  def title_inset(:segmented), do: "mt-0"
  def title_inset(_), do: "mt-1px"

  attr(:id, :string)
  attr(:bar_id, :string, required: true)
  attr(:size, :string, required: true)
  attr(:type, :atom, default: :seperated)
  attr(:title, :string)
  attr(:ready, :boolean, default: true)
  attr(:show_errors, :boolean, default: false)
  attr(:count, :integer, default: nil)
  attr(:index, :integer, default: nil)
  attr(:opts, :string, default: "")

  def tab(assigns) do
    ~H"""
    <div
      id={"tab_#{@size}_#{@id}"}
      data-tab-id={@id}
      data-bar-id={@bar_id}
      phx-hook="Tab"
      class={"tab flex flex-row gap-3 items-center justify-start focus:outline-none cursor-pointer #{@opts} #{idle_shape(@size, @type, @ready, @show_errors)}"}
      idle-class={idle_shape(@size, @type, @ready, @show_errors)}
      active-class={active_shape(@size, @type)}
    >
      <%= if @index do %>
        <div
          class={"flex-shrink-0 icon w-6 h-6 font-caption text-caption rounded-full flex items-center #{idle_icon(@ready, @show_errors)}"}
          idle-class={idle_icon(@ready, @show_errors)}
          active-class={active_icon(@type)}
        >
          <span class={"text-center w-full mt-1px #{center_correction_for_number(icon_text(@index, @ready, @show_errors, @count))}"}><%= icon_text(@index, @ready, @show_errors, @count) %></span>
        </div>
      <% end %>

      <%= if @title do %>
        <div class={"flex flex-col justify-center #{title_shape(@size, @type)}"}>
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
