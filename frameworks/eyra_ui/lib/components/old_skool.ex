defimpl Browser.Ua, for: Phoenix.LiveView.Socket do
  def to_ua(%{private: %{connect_info: %{user_agent: user_agent}}}), do: user_agent
  def to_ua(_), do: ""
end

defmodule EyraUI.Components.OldSkool do
  import Phoenix.HTML
  import Phoenix.LiveView.Helpers

  @moduledoc """
  Conveniences for reusable UI components
  """

  def is_native_web?(conn) do
    user_agent = Browser.Ua.to_ua(conn)
    String.match?(user_agent, ~r/NativeWrapper/i)
  end

  def is_mobile_web?(conn) do
    Browser.mobile?(conn) && !is_native_web?(conn)
  end

  def is_desktop_web?(conn) do
    !is_native_web?(conn) && !is_mobile_web?(conn)
  end

  def menu_button(label, path) do
    ~E"""
    <%= live_redirect to: path do %>
      <div class="flex items-center h-10 pl-3 pr-3 lg:pl-4 lg:pr-4 text-button font-button rounded-full hover:bg-grey4 focus:outline-none">
        <div><%= label %></div>
      </div>
    <% end %>
    """
  end

  def language_button(path, image) do
    ~E"""
    <a href= <%= path %> >
      <img src="<%= image %>"/>
    </a>
    """
  end

  def warning(message) do
    ~E"""
    <div class="mb-5 text-warning font-caption bg-warning bg-opacity-20 text-center leading-none rounded">
      <p class="inline-block mt-4 mb-4"><%= message %></p>
    </div>
    """
  end

  def footer(left, right) do
    ~E"""
    <div class="h-footer sm:h-footer-sm lg:h-footer-lg">
      <div class="flex">
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src="<%= left %>"/>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src="<%= right %>"/>
        </div>
      </div>
    </div>
    """
  end
end
