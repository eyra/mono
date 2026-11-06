defmodule Systems.Assignment.ErrorHTML do
  @moduledoc """
  Renders the pages shown when a participant follows a link that leads nowhere:
  the assignment has no budget capacity left, the assignment is not published,
  or an external survey returns to a task the researcher has removed.

  It lives in the Assignment system rather than the generic `MicaWeb.ErrorHTML`
  because both the copy and the meaning are assignment-specific; it reuses the
  shared `MicaWeb.ErrorHTML.error/1` chrome for the layout.
  """
  use MicaWeb, :html

  import MicaWeb.Layouts.Stripped.Composer
  import MicaWeb.Menus

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

  def task_unavailable(conn) do
    conn
    |> Phoenix.Controller.put_view(html: __MODULE__)
    |> Phoenix.Controller.render(:assignment_task_unavailable)
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

  def render("assignment_task_unavailable.html", assigns) do
    page(assigns, %{
      title: dgettext("eyra-assignment", "task_unavailable.title"),
      body: dgettext("eyra-assignment", "task_unavailable.body"),
      image: "/images/illustrations/404.svg",
      error_code: "task_unavailable"
    })
  end

  defp page(assigns, content) do
    assigns =
      assigns
      |> Map.merge(content)
      |> Map.put(:menus, build_menus(stripped_menus_config(), nil, nil))

    ~H"""
    <MicaWeb.ErrorHTML.error
      title={@title}
      menus={@menus}
      body={@body}
      image={@image}
      error_code={@error_code}
    />
    """
  end
end
