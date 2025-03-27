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
    <section class="py-12 bg-white">
      <div class="flex flex-col gap-8 md:flex-row justify-between mt-12 md:pl-14">
        <div class="w-full text-center md:text-left md:pr-12 xl:pr-0">
          <h1 class="text-title1 font-title1 font-bold text-grey1">
            What's Next?
          </h1>
          <p class="mt-6 font-intro text-2xl leading-8">
          The Next platform is an open and inclusive platform designed to accelerate research and knowledge creation.
          By integrating cutting-edge software services, Next empowers researchers with sustainable and privacy-conscious tools.
          Built on open-source principles and co-created with researchers, Next fosters innovation, transparency, and collaboration.
          </p>
          <div class="flex justify-center md:justify-start mt-8">
            <div class="w-full w-1/3">
            <Button.dynamic
              action={%{type: :redirect, to: "https://www.eyra.co/next-software-services"}}
              face={%{type: :primary, label: "Learn more"}}
            />
            </div>
          </div>
        </div>
        <div class="w-full hidden hidden md:block pr-12">
            <img src={~p"/images/landing_page/drawing.svg"} alt="Image displaying " class="w-full max-h-96" />
        </div>
      </div>
    </section>
    """
  end

  defp render_steps(assigns) do
    ~H"""
    <section class="py-16 px-6">
        <h2 class="text-title3 font-bold md:text-left pl-8">
          Here's how to get started
        </h2>
        <div class="mt-10 justify-around w-full flex flex-col md:flex-row gap-8 lg:gap-16 px-6">
          <%= render_step_card(%{
                image: ~p"/images/landing_page/geel-abstract.svg",
                title: "Log in",
                stepNumber: 1,
                description: "Create your free account and gain access to the Next platform with readily available software services.",
                button: %{label: "Create account", link: "/user/signup/creator"}
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/hout-abstract.svg",
                title: "Set up your study",
                stepNumber: 2,
                description: "Choose one of the software services and configure it to fit your research needs."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/blauw-abstract.svg",
                title: "Run your study",
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
        class="w-full h-46 lg:min-h-80 2xl:min-h-80 object-contain"
        src={@image}
        alt={@title}
      />
      <div class="p-4 lg:p-6">
        <div class="flex items-between gap-2">
          <div class="w-6 h-6 bg-primary text-white text-xs rounded-full flex items-center justify-center font-bold">
            {@stepNumber}
          </div>
          <h3 class="text-title5 font-bold">
            <%= @title %>
          </h3>
        </div>
        <p class="mt-4 text-introdesktop ">
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
    <section class="h-full pt-12 px-6 bg-white">
      <div class="px-12 flex justify-start items-center md:gap-10">
        <img class="h-64" src={~p"/images/landing_page/services-drawing.png"}/>
        <div class="flex flex-col justify-start items-start pr-20">
            <div class="pb-8 text-title1 font-title1 text-grey1">
              Available services
            </div>
            <div class="pb-6 flex flex-col justify-start items-start">
                <div class="justify-center text-2xl font-intro leading-8">
                  The Next platform is an open and inclusive platform designed to accelerate
                  research and knowledge creation. By integrating cutting-edge software
                  services, Next empowers researchers with sustainable and
                  privacy-conscious tools.
                </div>
                <div class="pt-16">
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
    <section class="h-full pt-24 px-6 bg-white">
        <h1 class="text-title1 font-bold text-center ">
          Wil je weten hoe het werkt?
        </h1>
        <div class="flex justify-center pt-6">
          <iframe
            class="h-[60vh] w-full rounded-lg mt-6 shadow"
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
