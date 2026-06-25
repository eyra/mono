defmodule Systems.Assignment.ErrorHTML do
  @moduledoc """
  Renders the "assignment is full" page shown when a participant tries to join an
  assignment that no longer has budget capacity.

  It lives in the Assignment system rather than the generic `CoreWeb.ErrorHTML`
  because both the copy and the meaning are assignment-specific; it reuses the
  shared `CoreWeb.ErrorHTML.error/1` chrome for the layout.
  """
  use CoreWeb, :html

  import CoreWeb.Layouts.Stripped.Composer
  import CoreWeb.Menus

  def render("assignment_full.html", assigns) do
    menus = build_menus(stripped_menus_config(), nil, nil)

    assigns =
      Map.merge(assigns, %{
        title: dgettext("eyra-assignment", "assignment_full.title"),
        body: dgettext("eyra-assignment", "assignment_full.body"),
        menus: menus,
        image: "/images/illustrations/503.svg",
        error_code: "assignment_full"
      })

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
