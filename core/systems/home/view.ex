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
    <section class="py-12">
      <div class=" flex flex-col md:flex-row items-center px-6 md:px-14">
        <!-- Left Content -->
        <div class="w-full md:w-2/3 text-center md:text-left md:mr-12 bg-primary">
          <h1 class="text-title2 font-bold text-grey1">
            Workplace for researchers
          </h1>
          <p class="mt-4 text-bodymedium text-grey1">
            The Next platform is an open-source web platform developed by Eyra
            that serves as an integration hub for sustainable software-as-a-service
            (SaaS) solutions, empowering research. These software services are co-created
            with researchers from various Dutch universities (e.g., UU, VU, RUG)
            and organizations such as ODISSEI.
          </p>
          <div class="mt-8 w-1/6">
            <Button.dynamic
              action={%{type: :redirect, to: "https://www.eyra.co/next-software-services"}}
              face={%{type: :primary, label: "Learn more"}}
            />
          </div>
        </div>

        <!-- Right Card -->
        <div class="w-full h-fit md:w-auto mt-8 md:mt-0 flex justify-center bg-black">
          <div class="max-w-card bg-grey6 shadow rounded-lg overflow-hidden">
            <img
              src={~p"/images/landing_page/yellow-abstract.webp"}
              class="max-w-full"
              alt="Abstract image"
            />
            <div class="p-6">
              <p class="text-bodymedium font-semibold">
                Sign in or explore the Next platform by creating a free account.
              </p>
              <div class="mt-4 flex space-x-4">
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
    <section class="bg-grey1 py-16">
      <div class="px-6">
        <h2 class="text-title3 font-bold text-white md:text-left pl-8">
          Here's how to get started
        </h2>
        <div class="mt-10 justify-around w-full flex flex-col md:flex-row gap-8 px-6">
          <%= render_step_card(%{
                image: ~p"/images/landing_page/yellow-abstract.webp",
                title: "Step 1: Log in",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/wood-abstract.webp",
                title: "Step 2: Set up your study",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
          <%= render_step_card(%{
                image: ~p"/images/landing_page/blue-abstract.webp",
                title: "Step 3: Run your study",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor."
               }) %>
        </div>
      </div>
    </section>
    """
  end

  defp render_step_card(assigns) do
    ~H"""
    <div class="bg-white w-full rounded overflow-hidden shadow">
      <img
        class="w-full h-64 object-cover"
        src={@image}
        alt={@title}
      />
      <div class="p-6">
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
    <section class="bg-white pt-12 pb-16">
      <div class="container mx-auto px-6">
        <h1 class="text-title2 font-bold text-grey1 text-center md:text-left">
          Wil je weten hoe het werkt?
        </h1>
        <div class="mt-6">
          <div class="aspect-w-16 aspect-h-9">
            <iframe
              class="min-w-full rounded-lg shadow"
              src="https://www.youtube.com/embed/dQw4w9WgXcQ"
              title="Sneak preview"
              allowfullscreen
            ></iframe>
          </div>
        </div>
      </div>
    </section>
    """
  end
end
