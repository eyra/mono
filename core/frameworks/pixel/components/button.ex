defmodule Frameworks.Pixel.Button do
  @moduledoc """
  A colored button with white text.
  """
  use CoreWeb, :html

  alias Frameworks.Pixel.Button.Action
  alias Frameworks.Pixel.Button.Face

  attr(:action, :map, required: true)
  attr(:face, :map, required: true)
  attr(:enabled?, :boolean, default: true)

  def dynamic(assigns) do
    ~H"""
    <%= if @enabled? do %>
      <.action {@action}>
        <.face {@face} />
      </.action>
    <% else %>
      <div class="opacity-30 cursor-not-allowed">
        <.face {@face} />
      </div>
    <% end %>
    """
  end

  attr(:buttons, :list, required: true)

  def dynamic_bar(assigns) do
    ~H"""
    <div class="flex flex-row gap-4">
      <%= for button <- @buttons do %>
        <.dynamic {button} />
      <% end %>
    </div>
    """
  end

  defp action_function(type) do
    case type do
      :fake -> &Action.fake/1
      :toggle -> &Action.toggle/1
      :click -> &Action.click/1
      :redirect -> &Action.redirect/1
      :send -> &Action.send/1
      :submit -> &Action.submit/1
      :sidepanel -> &Action.sidepanel/1
      :http -> &Action.http/1
      :http_get -> &Action.http_get/1
      :http_post -> &Action.http_post/1
      :http_delete -> &Action.http_delete/1
      :http_new -> &Action.http_new/1
    end
  end

  attr(:type, :atom, required: true)
  slot(:inner_block, required: true)

  def action(%{type: type} = assigns) do
    assigns =
      assign(assigns, %{
        function: action_function(type)
      })

    ~H"""
    <div class="h-full">
      <div class="flex flex-col h-full justify-center">
        <div class="flex-wrap">
          <.function_component function={@function} props={assigns} >
              <%= render_slot(@inner_block) %>
          </.function_component>
        </div>
      </div>
    </div>
    """
  end

  defp face_function(:primary, nil), do: &Face.primary/1
  defp face_function(:primary, _icon), do: &Face.primary_icon/1
  defp face_function(:secondary, _), do: &Face.secondary/1
  defp face_function(:label, nil), do: &Face.label/1
  defp face_function(:label, _icon), do: &Face.label_icon/1
  defp face_function(:forward, _), do: &Face.plain/1
  defp face_function(:plain, nil), do: &Face.plain/1
  defp face_function(:plain, _icon), do: &Face.plain_icon/1
  defp face_function(:menu_home, _), do: &Face.menu_home/1
  defp face_function(:menu_item, _), do: &Face.menu_item/1
  defp face_function(:link, _), do: &Face.link/1
  defp face_function(_, icon) when not is_nil(icon), do: &Face.icon/1
  defp face_function(_, _), do: &Face.primary/1

  attr(:type, :atom, required: true)
  attr(:icon, :any, default: nil)

  def face(%{type: type, icon: icon} = assigns) do
    function = face_function(type, icon)
    assigns = assign(assigns, %{function: function})

    ~H"""
    <.function_component function={@function} props={assigns} />
    """
  end

  attr(:to, :string, required: true)
  attr(:label, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")

  def primary(assigns) do
    ~H"""
    <Action.redirect to={@to}>
      <div class="flex">
        <div class={"flex-wrap pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px focus:outline-none rounded #{@bg_color}"}>
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button pl-4 pr-4">
              <%= @label %>
            </div>
          </div>
        </div>
      </div>
    </Action.redirect>
    """
  end

  attr(:path, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, default: "/images/back.svg")

  def back(assigns) do
    ~H"""
    <Action.redirect to={@path}>
      <div class="pt-1 pb-1 active:pt-5px active:pb-3px rounded pl-4 pr-4 bg-opacity-0">
        <div class="flex items-center">
          <div>
            <img class="mr-3 -mt-2px" src={@icon} alt={@label}>
          </div>
          <div class="h-10 focus:outline-none">
            <div class="flex flex-col justify-center h-full items-center">
              <div class="flex-wrap text-grey1 text-button font-button">
                <%= @label %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Action.redirect>
    """
  end

  attr(:path, :string, required: true)
  attr(:label, :string, required: true)

  def delete(assigns) do
    ~H"""
    <a
      href={@path}
      data-to={@path}
      data-csrf={Plug.CSRFProtection.get_csrf_token_for(@path)}
      data-method="delete"
    >
      <div class="flex">
        <div class="flex-wrap pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 border-delete focus:outline-none rounded bg-white">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-delete text-button font-button pl-4 pr-4">
              <%= @label %>
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end

  attr(:label, :string, required: true)
  attr(:click, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-white")

  def primary_alpine(assigns) do
    ~H"""
    <button
      @click={@click}
      class={"pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 #{@bg_color} #{@text_color}"}
      type="button"
    >
      <%= @label %>
    </button>
    """
  end

  attr(:to, :string, required: true)
  attr(:label, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:bg_color, :string, required: true)

  def primary_icon(assigns) do
    ~H"""
    <Action.redirect to={@to}>
      <div class={"pt-1 pb-1 active:pt-5px active:pb-3px active:shadow-top4px w-full rounded pl-4 pr-4 #{@bg_color}"}>
        <div class="flex justify-center items-center w-full">
          <div>
            <img class="mr-3 -mt-1" src={@icon} alt={@label}>
          </div>
          <div class="h-10 focus:outline-none">
            <div class="flex flex-col justify-center h-full items-center">
              <div class="text-white text-button font-button">
                <%= @label %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Action.redirect>
    """
  end

  attr(:label, :string, required: true)
  attr(:field, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-white")

  def primary_label(assigns) do
    ~H"""
    <label for={@field}>
      <div class={"cursor-pointer pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 #{@bg_color} #{@text_color}"}>
        <%= @label %>
      </div>
    </label>
    """
  end

  attr(:label, :string, required: true)
  attr(:event, :string, required: true)
  attr(:width, :string, default: "pl-4 pr-4")
  attr(:target, :any, default: nil)

  def primary_live_view(assigns) do
    ~H"""
    <button
      phx-target={@target}
      phx-click={@event}
      class={"pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded bg-primary #{@width}"}
    >
      <%= @label %>
    </button>
    """
  end

  attr(:to, :string, required: true)
  attr(:label, :string, required: true)
  attr(:bg_color, :string, required: true)

  def primary_wide(assigns) do
    ~H"""
    <Action.redirect to={@to}>
      <div class={"flex w-full #{@bg_color} rounded justify-center items-center pl-4 pr-4"}>
        <div class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px focus:outline-none">
          <div class="flex flex-col justify-center h-full items-center rounded">
            <div class="text-white text-button font-button">
              <%= @label %>
            </div>
          </div>
        </div>
      </div>
    </Action.redirect>
    """
  end

  attr(:label, :string, required: true)
  attr(:click, :string, required: true)
  attr(:border_color, :string, default: "border-primary")
  attr(:text_color, :string, default: "text-primary")

  def secondary_alpine(assigns) do
    ~H"""
    <button
      @click={@click}
      class={"pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 #{@border_color} #{@text_color}"}
      type="button"
    >
      <%= @label %>
    </button>
    """
  end

  attr(:label, :string, required: true)
  attr(:field, :string, required: true)
  attr(:border_color, :string, default: "border-primary")
  attr(:text_color, :string, default: "text-primary")

  def secondary_label(assigns) do
    ~H"""
    <label for={@field}>
      <div class={"cursor-pointer pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 #{@border_color} #{@text_color}"}>
        <%= @label %>
      </div>
    </label>
    """
  end

  attr(:label, :string, required: true)
  attr(:event, :string, required: true)
  attr(:color, :string, default: "text-delete")
  attr(:width, :string, default: "pl-4 pr-4")
  attr(:target, :any)

  def secondary_live_view(assigns) do
    ~H"""
    <button
      phx-target={@target}
      phx-click={@event}
      class={"pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button focus:outline-none rounded bg-opacity-0 #{@color} #{@width}"}
    >
      <%= @label %>
    </button>
    """
  end

  attr(:label, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:alpine_onclick, :string, default: "")
  attr(:target, :string, default: "")

  def submit(assigns) do
    ~H"""
    <button
      x-on:click={@alpine_onclick}
      class={"pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 #{@bg_color}"}
      type="submit"
      phx-target={@target}
    >
      <%= @label %>
    </button>
    """
  end

  attr(:label, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")

  def submit_wide(assigns) do
    ~H"""
    <button
      class={"w-full pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 #{@bg_color}"}
      type="submit"
    >
      <%= @label %>
    </button>
    """
  end

  attr(:id, :string, required: true)
  attr(:overlay?, :boolean, default: false)
  attr(:action, :map, required: true)
  attr(:face, :map, required: true)

  def menu(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="NativeWrapper"
      @click={"nativeWrapperHook.toggleSidePanel(); $parent.overlay = #{@overlay?}"}
    >
      <.action {@action}>
        <.face {@face} />
      </.action>
    </div>
    """
  end
end
