defmodule CoreWeb.ErrorView do
  use CoreWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  def render("500.html", assigns) do
    render_error("500_page.html", "Internal Server Error", assigns)
  end

  def render("503.html", assigns) do
    render_error("503_page.html", "Service Unavailable", assigns)
  end

  def render("403.html", assigns) do
    render_error("403_page.html", "Access Denied", assigns)
  end

  def render("404.html", assigns) do
    render_error("404_page.html", "Page Not Found", assigns)
  end

  defp render_error(page, title, %{conn: conn}) do
    render(CoreWeb.ErrorView, page,
      layout: {CoreWeb.LayoutView, "error.html"},
      conn: conn,
      title: title
    )
  end
end
