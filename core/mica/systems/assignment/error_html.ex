defmodule Systems.Assignment.ErrorHTML do
  @moduledoc """
  Renders the pages shown when a participant follows a participation link that
  leads nowhere: the assignment has no budget capacity left, or the assignment
  is not published.

  It lives in the Assignment system rather than the generic `CoreWeb.ErrorHTML`
  because both the copy and the meaning are assignment-specific; it reuses the
  shared `CoreWeb.ErrorHTML.error/1` chrome for the layout.
  """
  use CoreWeb, :html

  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  def full(conn) do
    conn
    |> Phoenix.Controller.put_view(html: __MODULE__)
    |> Phoenix.Controller.render(:assignment_full)
  end

  def unavailable(conn) do
    conn
    |> Phoenix.Controller.put_view(html: __MODULE__)
    |> Phoenix.Controller.render(:assignment_unavailable)
  end

  def render("assignment_full.html", assigns) do
    page(assigns, %{
      title: dgettext("eyra-assignment", "assignment_full.title"),
      body: dgettext("eyra-assignment", "assignment_full.body"),
      image: "/images/illustrations/503.svg",
      error_code: "assignment_full"
    })
  end

  def render("assignment_unavailable.html", assigns) do
    page(assigns, %{
      title: dgettext("eyra-assignment", "assignment_unavailable.title"),
      body: dgettext("eyra-assignment", "assignment_unavailable.body"),
      image: "/images/illustrations/404.svg",
      error_code: "assignment_unavailable"
    })
  end

  defp page(assigns, content) do
    assigns =
      assigns
      |> Map.merge(content)
      |> Map.put(:menus, build_menus(stripped_menus_config(), nil, nil))

    ~H"""
    <CoreWeb.ErrorHTML.error
      title={@title}
      menus={@menus}
      body={@body}
      image={@image}
      error_code={@error_code}
    />
    """
  end
end
