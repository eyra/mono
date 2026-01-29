defmodule CoreWeb.ErrorHTML do
  use CoreWeb, :html
  import CoreWeb.Layouts.Stripped.Html
  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  defp body("403.html", status), do: dgettext("eyra-error", "403.body", status: status)
  defp body("404.html", status), do: dgettext("eyra-error", "404.body", status: status)
  defp body("500.html", status), do: dgettext("eyra-error", "500.body", status: status)
  defp body("503.html", status), do: dgettext("eyra-error", "503.body", status: status)
  defp body(_, status), do: dgettext("eyra-error", "generic.body", status: status)

  defp image("403.html"), do: "/images/illustrations/403.svg"
  defp image("404.html"), do: "/images/illustrations/404.svg"
  defp image("500.html"), do: "/images/illustrations/500.svg"
  defp image("503.html"), do: "/images/illustrations/503.svg"
  defp image(_), do: nil

  defp status(template), do: Phoenix.Controller.status_message_from_template(template)

  defp error_code("403.html"), do: "403"
  defp error_code("404.html"), do: "404"
  defp error_code("500.html"), do: "500"
  defp error_code("503.html"), do: "503"
  defp error_code(_), do: "unknown"

  def render(template, assigns) do
    status = status(template)
    menus = build_menus(stripped_menus_config(), nil, nil)

    assigns =
      Map.merge(assigns, %{
        status: status,
        menus: menus,
        body: body(template, status),
        image: image(template),
        error_code: error_code(template)
      })

    ~H"""
     <.error
      title={@status}
      menus={@menus}
      body={@body}
      image={@image}
      error_code={@error_code}
    />
    """
  end

  attr(:title, :string, required: true)
  attr(:body, :string, required: true)
  attr(:image, :string, default: nil)
  attr(:menus, :map, required: true)
  attr(:error_code, :string, required: true)

  def error(assigns) do
    ~H"""
    <.stripped title={@title} menus={@menus} >
        <Area.content>
            <Margin.y id={:page_top} />
            <div class="flex flex-col md:flex-row gap-10 items-center md:items-start" data-testid={"error-#{@error_code}"}>
                <div>
                    <div class="text-title3 font-title3 sm:text-title2 lg:text-title1 lg:font-title1 text-grey1"><%= dgettext("eyra-error","page.title") %></div>
                    <div class="mb-6 md:mb-8"></div>
                    <div class="text-bodymedium sm:text-bodylarge font-body text-grey1"><%= raw(@body) %></div>
                    <div class="mb-6 md:mb-8"></div>
                </div>
                <%= if @image do %>
                  <div class="flex-shrink-0">
                      <img src={@image} alt="" />
                  </div>
                <% end %>
            </div>
        </Area.content>
    </.stripped>
    """
  end
end
