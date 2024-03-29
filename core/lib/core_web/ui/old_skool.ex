defimpl Browser.Ua, for: Phoenix.LiveView.Socket do
  def to_ua(%{private: %{connect_info: %{user_agent: user_agent}}}), do: user_agent
  def to_ua(_), do: ""
end

defmodule CoreWeb.UI.OldSkool do
  import Phoenix.Component
  import CoreWeb.UI.Footer

  @moduledoc """
  Conveniences for reusable UI components
  """

  def native_web?(conn) do
    user_agent = Browser.Ua.to_ua(conn)
    String.match?(user_agent, ~r/NativeWrapper/i)
  end

  def mobile_web?(conn) do
    Browser.mobile?(conn) && !native_web?(conn)
  end

  def desktop_web?(conn) do
    !native_web?(conn) && !mobile_web?(conn)
  end

  def push_supported?(conn) do
    Browser.chrome?(conn) || Browser.firefox?(conn)
  end

  def warning(assigns, message) do
    assigns = assign(assigns, :message, message)

    ~H"""
    <div class="mb-5 text-warning font-caption bg-warning bg-opacity-20 text-center leading-none rounded">
      <p class="inline-block mt-4 mb-4"><%= @message %></p>
    </div>
    """
  end

  # def primary_button(%{assigns: assigns}, label, to), do: primary_button(assigns, label, to)

  def primary_button(assigns, label, to) do
    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:to, to)

    ~H"""
    <div class="flex flex-row">
      <div class="flex-wrap">
          <a href={@to} >
            <div class="pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 bg-primary text-white">
              <%= @label %>
            </div>
          </a>
      </div>
    </div>
    """
  end

  def secondary_button(%{assigns: assigns}, label, to), do: secondary_button(assigns, label, to)

  def secondary_button(assigns, label, to) do
    assigns =
      assigns
      |> assign(:label, label)
      |> assign(:to, to)

    ~H"""
    <div class="flex flex-row">
      <div class="flex-wrap">
          <a href={@to} >
            <div class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button rounded bg-opacity-0 pr-4 pl-4 text-primary border-primary">
              <%= @label %>
            </div>
          </a>
      </div>
    </div>
    """
  end

  def page_footer(%{assigns: assigns}), do: page_footer(assigns)

  def page_footer(assigns) do
    ~H"""
    <div class="bg-white">
      <.content_footer />
    </div>
    """
  end

  def tabbar(assigns, _tabs) do
    ~H"""
    <div class="bg-white">
      <.content_footer />
    </div>
    """
  end
end
