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
      <Margin.y id="page_top" />
      <div class="bg-grey6">
        <%= render_intro(assigns) %>
        <%= render_steps(assigns) %>
        <%= render_video(assigns) %>
      </div>
    </div>
    """
  end

  defp render_intro(assigns) do
    ~H"""
    <section class="py-12 bg-white">
      <div class="flex flex-col gap-8 sm:gap-16 md:gap-0 md:flex-row justify-between mt-12 md:pl-14">
        <div class="w-full md:w-3/4 l text-center md:text-left md:pr-12 xl:pr-0">
          <h1 class="text-title2 xl:text-title1 font-bold text-grey1">
            Workplace for researchers
          </h1>
          <p class="mt-4 text-bodymedium lg:text-2xl xl:text-3xl 2xl:text-4xl text-grey1 px-4 md:px-0 ">
            The Next platform is an open-source web platform developed by Eyra
            that serves as an integration hub for sustainable software-as-a-service
            (SaaS) solutions, empowering research. These software services are co-created
            with researchers from various Dutch universities (e.g., UU, VU, RUG)
            and organizations such as ODISSEI.
          </p>
          <div class="flex justify-center md:justify-start mt-8">
            <div class="w-1/2 lg:w-1/5 xl:w-1/6 ">
            <Button.dynamic
              action={%{type: :redirect, to: "https://www.eyra.co/next-software-services"}}
              face={%{type: :primary, label: "Learn more"}}
            />
            </div>
          </div>
        </div>
        <div class="w-full md:w-1/2 px-4 sm:px-16 md:px-0 lg:w-1/4 xl:w-1/5 text-center md:text-left">
          <div class="rounded-lg shadow-xl">
              <img
                src={~p"/images/landing_page/yellow-abstract.webp"}
                class="w-full rounded-t max-h-80"
                alt="Abstract image"
              />
              <div class="p-4 sm:p-6">
                  <p class="sm:text-lg lg:text-xl 2xl:text-2xl lg:font-semibold">
                    Sign in or explore the Next platform by creating a free account.
                  </p>
                  <div class="mt-4 flex flex-col 2xl:flex-row items-between gap-2 justify-between  text-center">
                    <Button.dynamic
                      action={%{type: :click, code: "alert('Hello!')"}}
                      face={%{type: :primary, label: "Meld je aan"}}
                    />
                    <Button.dynamic
                      action={%{type: :click, code: "alert('Hello!')"}}
                      face={%{type: :secondary, label: "inloggen"}}
                    />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp render_steps(assigns) do
    ~H"""
    <section class="bg-grey1 py-16 px-6">
        <h2 class="text-title3 font-bold text-white md:text-left pl-8">
          Here's how to get started
        </h2>
        <div class="mt-10 justify-around w-full flex flex-col md:flex-row gap-8 lg:gap-8 px-6">
          <%= render_step_card(%{
                image: ~p"/images/landing_page/geel-abstract.svg",
                title: "Step 1: Log in",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/hout-abstract.svg",
                title: "Step 2: Set up your study",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/blauw-abstract.svg",
                title: "Step 3: Run your study",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
        </div>
    </section>
    """
  end

  defp render_step_card(assigns) do
    ~H"""
    <div class="bg-white w-full rounded xl:rounded-t-2xl overflow-hidden shadow">
      <img
        class="w-full h-46 lg:min-h-80 2xl:min-h-80 object-cover"
        src={@image}
        alt={@title}
      />
      <div class="p-4 lg:p-6">
        <h3 class="text-title5 font-bold">
          <%= @title %>
        </h3>
        <p class="mt-4 text-bodymedium">
          <%= @description %>
        </p>
      </div>
    </div>
    """
  end

  defp render_video(assigns) do
    ~H"""
    <section class="h-full pt-12 px-6 bg-white">
        <h1 class="text-title2 font-bold text-grey1 text-center md:text-left">
          Wil je weten hoe het werkt?
        </h1>
        <div class="flex justify-center">
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
