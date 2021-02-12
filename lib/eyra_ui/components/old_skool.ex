defmodule LinkWeb.Components.OldSkool do
  import Phoenix.HTML
  alias LinkWeb.Router.Helpers, as: Routes

  @moduledoc """
  Conveniences for reusable UI components
  """

  def menu_button(label, path) do
    ~E"""
    <a href= <%= path %>>
      <div class="flex items-center h-10 pl-3 pr-3 lg:pl-4 lg:pr-4 text-button font-button rounded-full hover:bg-grey4 focus:outline-none">
        <div><%= label %></div>
      </div>
    </a>
    """
  end

  def language_button(conn, locale) do
    path = Routes.language_switch_path(conn, :index, locale, redir: conn.request_path)
    image = Routes.static_path(conn, "/images/" <> locale <> ".svg")

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

  def footer(conn) do
    left = Routes.static_path(conn, "/images/footer-left.svg")
    right = Routes.static_path(conn, "/images/footer-right.svg")

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
