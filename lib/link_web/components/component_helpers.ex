
defmodule LinkWeb.Components.ComponentHelpers do
  alias Phoenix.Naming
  alias LinkWeb.Components

  @moduledoc """
  Conveniences for reusable UI components
  """

  import LinkWeb.Gettext
  import LinkWeb.ErrorHelpers

  @spec c(any, atom, any) :: any
  def c(namespace, name \\ :index, assigns \\ []) do
    component(namespace, template(name), assigns)
  end

  def c(namespace, name, assigns, opts) do
    component(namespace, template(name), assigns, opts)
  end

  @spec component(any, any, any) :: any
  def component(namespace, template, assigns) do
    apply(
      view(namespace),
      :render,
      [template, assigns]
    )
  end

  def component(namespace, template, assigns, do: block) do
    apply(
      view(namespace),
      :render,
      [template, Keyword.merge(assigns, do: block)]
    )
  end

  def view_opts(namespace) do
    [
      root: "lib/link_web/components/#{namespace}/templates",
      namespace: LinkWeb,
      path: ""
    ]
  end

  def email_field(form, field)  do

    type = "text"
    id = "user_email"
    name = "user[email]"
    label = dgettext("eyra-account", "email.label")
    warning = error_tag(form, field) |> Enum.at(0)

    c(:form_field, :input, [warning: warning, label: label, type: type, id: id, name: name])
  end

  def password_field(form, field)  do
    type = "password"
    warning = error_tag(form, field) |> Enum.at(0)

    id = "user_#{field}"
    name = "user[#{field}]"

    label = cond do
      field === :password_confirmation -> dgettext("eyra-account", "password.confirmation.label")
      field === :current_password -> dgettext("eyra-account", "password.current.label")
      true -> dgettext("eyra-account", "password.label")
    end

    c(:form_field, :input, [warning: warning, label: label, type: type, id: id, name: name])
  end


  def primary_button(label, path, method \\ :get, color \\ "grey1") do
    bg_color = "bg-" <> color
    c(:custom_button, :primary, [label: label, method: method, path: path, color: bg_color])
  end

  def primary_icon_button(label, icon, path, color \\ "grey1") do
    bg_color = "bg-" <> color
    c(:custom_button, :primary_icon, [label: label, method: :get, icon: icon, path: path, color: bg_color])
  end

  def submit_button(label, color \\ "grey1") do
    bg_color = "bg-" <> color
    c(:custom_button, :submit, [label: label, color: bg_color])
  end

  def link_button(label, path) do
    c(:custom_button, :link, [label: label, path: path])
  end

  def back_button(conn) do
    c(:custom_button, :back, [conn: conn])
  end

  def warning(message) do
    c(:message, :warning, [message: message])
  end

  defp view(name) do
    module_name = Naming.camelize("#{name}") <> "View"
    Module.concat(Components, module_name)
  end

  defp template(name) when is_atom(name) do
    "#{name}.html"
  end
end
