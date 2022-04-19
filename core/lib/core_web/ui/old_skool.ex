defimpl Browser.Ua, for: Phoenix.LiveView.Socket do
  def to_ua(%{private: %{connect_info: %{user_agent: user_agent}}}), do: user_agent
  def to_ua(_), do: ""
end

defmodule CoreWeb.UI.OldSkool do
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

  def is_push_supported?(conn) do
    Browser.chrome?(conn) || Browser.firefox?(conn)
  end

  def language_switch_item(%{request_path: request_path, assigns: assigns} = conn) do
    [locale | _] = CoreWeb.Menu.Helpers.supported_languages()

    path =
      CoreWeb.Router.Helpers.language_switch_path(conn, :index, locale.id, redir: request_path)

    ~H"""
    <a href={path}>
      <img src={"/images/icons/#{locale.id}.svg"} alt={"Switch language to #{locale.name}"}/>
    </a>
    """
  end

  def warning(assigns, message) do
    ~H"""
    <div class="mb-5 text-warning font-caption bg-warning bg-opacity-20 text-center leading-none rounded">
      <p class="inline-block mt-4 mb-4"><%= message %></p>
    </div>
    """
  end

  def footer(assigns, left, right) do
    ~H"""
    <div class="h-footer sm:h-footer-sm lg:h-footer-lg">
      <div class="flex">
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={left} alt=""/>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={right} alt="" />
        </div>
      </div>
    </div>
    """
  end

  def primary_button(%{assigns: assigns}, label, to), do: primary_button(assigns, label, to)

  def primary_button(assigns, label, to) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-wrap">
          <a href={to} >
            <div class="pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button rounded pr-4 pl-4 bg-primary text-white">
              <%= label %>
            </div>
          </a>
      </div>
    </div>
    """
  end

  def secondary_button(%{assigns: assigns}, label, to), do: secondary_button(assigns, label, to)

  def secondary_button(assigns, label, to) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-wrap">
          <a href={to} >
            <div class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button rounded bg-opacity-0 pr-4 pl-4 text-primary border-primary">
              <%= label %>
            </div>
          </a>
      </div>
    </div>
    """
  end

  def hero_small(%{assigns: assigns}, title), do: hero_small(assigns, title)

  def hero_small(assigns, title) do
    ~H"""
    <div class="flex h-header2 items-center sm:h-header2-sm lg:h-header2-lg text-white bg-primary overflow-hidden" data-native-title={title}>
      <div class="flex-grow flex-shrink-0">
          <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
            <%= title %>
          </p>
      </div>
      <div class="flex-none h-header2 sm:h-header2-sm lg:h-header2-lg w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
          <img src="/images/illustration.svg" alt=""/>
      </div>
    </div>
    """
  end

  def stripped_navbar(%{assigns: assigns}, icon), do: stripped_navbar(assigns, icon)

  def stripped_navbar(assigns, icon) do
    ~H"""
    <div class="h-topbar sm:h-topbar-sm lg:h-topbar-lg pl-6 md:pl-0 flex-shrink-0" >
      <div class="flex flex-row h-full">
          <div class="flex-wrap">
              <div class="flex flex-col items-center justify-center h-full">
                  <div class="flex-wrap cursor-pointer">
                      <a
                      class="cursor-pointer"
                      data-phx-link="redirect"
                      data-phx-link-state="replace"
                      href="/"
                      >
                          <img class="h-8 sm:h-12" src={icon} alt="Home" />
                      </a>
                  </div>
              </div>
          </div>
      </div>
    </div>
    """
  end

  def page_footer(%{assigns: assigns}), do: page_footer(assigns)

  def page_footer(assigns) do
    ~H"""
    <div class="bg-white">
      <%= footer assigns, "/images/footer-left.svg", "/images/footer-right.svg" %>
    </div>
    """
  end
end
