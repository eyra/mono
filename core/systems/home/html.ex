defmodule Systems.Home.HTML do
  use CoreWeb, :html

  import Frameworks.Pixel.NumberIcon

  def intro(assigns) do
    ~H"""
    <section class="py-6 lg:py-12 bg-white">
      <div class="flex gap-8 lg:flex-row justify-between lg:mt-12 lg:pl-14">
        <div class="w-full px-6 lg:px-0 text-left lg:pr-12 xl:pr-0">
          <h1 class="text-title3 lg:text-title1 font-title1 font-bold text-grey1">
            <%= dgettext("eyra-crew", "home.intro.title") %>
          </h1>
          <p class="mt-6 text-xl lg:text-2xl font-intro leading-7">
            <%= dgettext("eyra-crew", "home.intro.description") %>
          </p>
          <div class="flex justify-start mt-8">
            <Button.dynamic
              action={%{type: :redirect, to: "https://eyra.co/software-development"}}
              face={%{type: :primary, label: dgettext("eyra-crew", "home.intro.learn_more_button")}}
            />
            </div>
          </div>
          <div class="w-full hidden hidden lg:block pr-12">
              <img src={~p"/images/landing_page/drawing.svg"} alt={dgettext("eyra-crew", "home.intro.image_alt")} class="w-full max-h-96" />
          </div>
        </div>
    </section>
    """
  end

  def steps(assigns) do
    ~H"""
    <section class="py-6 lg:py-16 lg:px-6">
        <h2 class="text-title3 font-title3 pl-6 text-grey-1">
          <%= dgettext("eyra-crew", "home.steps.title") %>
        </h2>
        <div class="mt-6 justify-around w-full flex flex-col lg:flex-row gap-8 lg:gap-16 px-6 ">
          <.step_card
            image={~p"/images/landing_page/geel-abstract.svg"}
            title={dgettext("eyra-crew", "home.steps.step1.title")}
            stepNumber={1}
            description={dgettext("eyra-crew", "home.steps.step1.description")}
            button={%{label: dgettext("eyra-crew", "home.steps.step1.button"), link: "/user/signup/creator"}}
          />
          <.step_card
            image={~p"/images/landing_page/hout-abstract.svg"}
            title={dgettext("eyra-crew", "home.steps.step2.title")}
            stepNumber={2}
            description={dgettext("eyra-crew", "home.steps.step2.description")}
          />
          <.step_card
            image={~p"/images/landing_page/blauw-abstract.svg"}
            title={dgettext("eyra-crew", "home.steps.step3.title")}
            stepNumber={3}
            description={dgettext("eyra-crew", "home.steps.step3.description")}
          />
        </div>
    </section>
    """
  end

  attr(:image, :string, required: true)
  attr(:title, :string, required: true)
  attr(:stepNumber, :integer, required: true)
  attr(:description, :string, required: true)
  attr(:button, :map, default: nil)

  defp step_card(assigns) do
    ~H"""
    <div class="bg-white w-full rounded overflow-hidden shadow-lg">
      <img
        class="w-full h-32 lg:h-48 object-cover"
        src={@image}
        alt={@title}
      />
      <div class="p-4 lg:p-6">
        <div class="flex items-between gap-2">
          <.number_icon number={@stepNumber} active={true} />
          <h3 class="text-title5 font-title5 text-grey1">
            <%= @title %>
          </h3>
        </div>
        <p class="mt-4 text-lg lg:text-introdesktop ">
          <%= @description %>
        </p>
        <%= if @button do %>
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

  def available_services(assigns) do
    ~H"""
    <section class="h-full pt-6 lg:pt-12 px-6 bg-white">
      <div class="lg:px-12 flex lg:flex-row justify-start items-center lg:gap-10">
          <img class="h-64 hidden lg:block" src={~p"/images/landing_page/services-drawing.png"} alt={dgettext("eyra-crew", "home.services.image_alt")}/>
          <div class="flex flex-col justify-start items-start lg:pr-8 lg:pr-20">
              <div class="pb-6 lg:pb-8 text-title4 font-title4 lg:text-title1 lg:font-title1 text-grey1">
                <%= dgettext("eyra-crew", "home.services.title") %>
              </div>
              <div class="pb-6 flex flex-col justify-start items-start">
                  <div class="pb-6 justify-center text-xl lg:text-2xl font-intro leading-7">
                    <%= dgettext("eyra-crew", "home.services.description") %>
                  </div>
                  <div class="lg:pt-16">
                    <Button.dynamic
                      action={%{type: :redirect, to: "https://eyra.co/next-software-services"}}
                      face={%{type: :primary, label: dgettext("eyra-crew", "home.services.button")}}
                    />
                  </div>
              </div>
          </div>
      </div>
    </section>
    """
  end

  def video(assigns) do
    ~H"""
    <section class="h-full pt-8 lg:pt-24 px-6 bg-white">
        <h1 class="text-title3 font-title3 lg:text-title1 lg:font-title1 text-center text-grey1">
          <%= dgettext("eyra-crew", "home.video.title") %>
        </h1>
      <div class="flex justify-center pt-6">
      <!-- XS-SM: up to 639px -->
      <iframe
        loading="lazy"
        class="block sm:hidden w-[290px] h-[202px] rounded-lg shadow"
        src="https://www.loom.com/embed/f9f37259d1a84cffbe9baddc1d982603"
        allowfullscreen
      ></iframe>

      <!-- SM - XL: 640px – 1023px -->
      <iframe
        loading="lazy"
        class="hidden sm:block xl:hidden w-[600px] h-[360px] rounded-lg shadow"
        src="https://www.loom.com/embed/f9f37259d1a84cffbe9baddc1d982603"
        allowfullscreen
      ></iframe>

      <!-- XL: from 1024px up -->
      <iframe
          loading="lazy"
          class="hidden xl:block h-1/2 lg:h-[60vh] w-3/4 rounded-lg mt-6 shadow"
          src="https://www.loom.com/embed/f9f37259d1a84cffbe9baddc1d982603?sid=1d3270c1-e5ce-4dbb-921c-0fab4fcb3efc"
          title={dgettext("eyra-crew", "home.video.preview_title")}
          allowfullscreen
        >
      </iframe>
      </div>
    </section>
    """
  end
end
