
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
    confirmation = field === :password_confirmation

    id = if confirmation do "user_password_confirmation" else "user_password" end
    name = if confirmation do "user[password_confirmation]" else "user[password]" end
    label = if confirmation do dgettext("eyra-account", "password.confirmation.label") else dgettext("eyra-account", "password.label") end
    warning = error_tag(form, field) |> Enum.at(0)

    c(:form_field, :input, [warning: warning, label: label, type: type, id: id, name: name])
  end

  defp view(name) do
    module_name = Naming.camelize("#{name}") <> "View"
    Module.concat(Components, module_name)
  end

  defp template(name) when is_atom(name) do
    "#{name}.html"
  end
end
