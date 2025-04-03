defmodule Systems.Home.View do
  use CoreWeb, :live_component

  @impl true
  def update(%{blocks: blocks}, socket) do
    {:ok, update_blocks(socket, blocks)}
  end

  defp update_blocks(socket, []), do: socket

  defp update_blocks(socket, [{name, map} | tail]) do
    socket
    |> add_child(name, map)
    |> update_blocks(tail)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-grey6">
        <%= render_intro(assigns) %>
        <%= render_steps(assigns) %>
        <%= render_available_services(assigns) %>
        <%= render_video(assigns) %>
      </div>
    </div>
    """
  end

  defp render_intro(assigns) do
    ~H"""
    <section class="py-6 lg:py-12 bg-white">
      <div class="flex gap-8 lg:flex-row justify-between lg:mt-12 lg:pl-14">
        <div class="w-full px-6 lg:px-0 text-left lg:pr-12 xl:pr-0">
          <h1 class="text-title3 lg:text-title1 font-title1 font-bold text-grey1">
            What's Next?
          </h1>
          <p class="mt-6 text-xl lg:text-2xl font-intro leading-7">
            The Next platform is an open and inclusive platform designed to accelerate research and knowledge creation.
            By integrating cutting-edge software services, Next empowers researchers with sustainable and privacy-conscious tools.
            Built on open-source principles and co-created with researchers, Next fosters innovation, transparency, and collaboration.
          </p>
          <div class="flex justify-start mt-8">
            <Button.dynamic
              action={%{type: :redirect, to: "/next-software-services"}}
              face={%{type: :primary, label: "Learn more"}}
            />
            </div>
          </div>
          <div class="w-full hidden hidden lg:block pr-12">
              <img src={~p"/images/landing_page/drawing.svg"} alt="Image displaying " class="w-full max-h-96" />
          </div>
        </div>
    </section>
    """
  end

  defp render_steps(assigns) do
    ~H"""
    <section class="py-6 lg:py-16 lg:px-6">
        <h2 class="text-title3 font-title3 pl-6 text-grey-1">
          How to get started?
        </h2>
        <div class="mt-6 justify-around w-full flex flex-col lg:flex-row gap-8 lg:gap-16 px-6 ">
          <%= render_step_card(%{
                image: ~p"/images/landing_page/geel-abstract.svg",
                title: "Sign up",
                stepNumber: 1,
                description: "Create your free account and gain access to the Next platform with readily available software services.",
                button: %{label: "Create account", link: "/user/signup/creator"}
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/hout-abstract.svg",
                title: "Configure",
                stepNumber: 2,
                description: "Choose one of the software services and configure it to fit your research needs."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/blauw-abstract.svg",
                title: "Preview",
                stepNumber: 3,
                description: "See your configuration in action, make adjustments, and immediately observe the effect."
               }) %>
        </div>
    </section>
    """
  end

  defp render_step_card(assigns) do
    ~H"""
    <div class="bg-white w-full rounded overflow-hidden drop-shadow-lg">
      <img
        class="w-full h-32 lg:h-48 object-cover"
        src={@image}
        alt={@title}
      />
      <div class="p-4 lg:p-6">
        <div class="flex items-between gap-2">
          <div class="w-6 h-6 bg-primary text-white text-xs rounded-full flex items-center justify-center font-bold">
            {@stepNumber}
          </div>
          <h3 class="text-title5 font-title5 text-grey1">
            <%= @title %>
          </h3>
        </div>
        <p class="mt-4 text-lg lg:text-introdesktop ">
          <%= @description %>
        </p>
        <%= if assigns[:button] do %>
          <div class="flex justify-start mt-6">
            <Button.dynamic
              action={%{type: :redirect, to: @button.link}}
              face={%{type: :primary, label: @button.label}}
            />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_available_services(assigns) do
    ~H"""
    <section class="h-full pt-6 lg:pt-12 px-6 bg-white">
      <div class="lg:px-12 flex lg:flex-row justify-start items-center lg:gap-10">
          <img class="h-64 hidden lg:block" src={~p"/images/landing_page/services-drawing.png"}/>
          <div class="flex flex-col justify-start items-start lg:pr-8 lg:pr-20">
              <div class="pb-6 lg:pb-8 text-title4 font-title4 lg:text-title1 lg:font-title1 text-grey1">
                Available services
              </div>
              <div class="pb-6 flex flex-col justify-start items-start">
                  <div class="pb-6 justify-center text-xl lg:text-2xl font-intro leading-7">
                    The Next platform is an open and inclusive platform designed to accelerate
                    research and knowledge creation. By integrating cutting-edge software
                    services, Next empowers researchers with sustainable and
                    privacy-conscious tools.
                  </div>
                  <div class="lg:pt-16">
                    <Button.dynamic
                      action={%{type: :redirect, to: "/next-software-services"}}
                      face={%{type: :primary, label: "Available services"}}
                    />
                  </div>
              </div>
          </div>
      </div>
    </section>
    """
  end

  defp render_video(assigns) do
    ~H"""
    <section class="h-full pt-8 lg:pt-24 px-6 bg-white">
        <h1 class="text-title3 font-title3 lg:text-title1 lg:font-title1 text-center text-grey1">
          Want to know how this works?
        </h1>
        <div class="flex justify-center pt-6">
          <iframe
            class="h-1/2 lg:h-[60vh] w-full rounded-lg mt-6 shadow"
            src="https://www.youtube.com/embed/dQw4w9WgXcQ"
            title="Sneak preview"
            allowfullscreen
          >
          </iframe>
        </div>
    </section>
    """
  end
end
