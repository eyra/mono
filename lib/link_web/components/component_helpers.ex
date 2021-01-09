defmodule LinkWeb.Components.ComponentHelpers do
  alias Phoenix.Naming
  alias LinkWeb.Components
  alias LinkWeb.Router.Helpers, as: Routes

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

  def email_field(form, field) do
    type = "text"
    id = "user_email"
    name = "user[email]"
    label = dgettext("eyra-account", "email.label")
    warning = error_tag(form, field) |> Enum.at(0)

    c(:form_field, :input, warning: warning, label: label, type: type, id: id, name: name)
  end

  def password_field(form, field) do
    type = "password"
    warning = error_tag(form, field) |> Enum.at(0)

    id = "user_#{field}"
    name = "user[#{field}]"

    label =
      cond do
        field === :password_confirmation ->
          dgettext("eyra-account", "password.confirmation.label")

        field === :current_password ->
          dgettext("eyra-account", "password.current.label")

        true ->
          dgettext("eyra-account", "password.label")
      end

    c(:form_field, :input, warning: warning, label: label, type: type, id: id, name: name)
  end

  def checkbox_field(form, field, text \\ "checkbox") do
    c(:form_field, :checkbox, form: form, field: field, text: text)
  end

  def text_field(form, field, text \\ "text") do
    warning = error_tag(form, field) |> Enum.at(0)

    c(:form_field, :text, form: form, field: field, text: text, warning: warning)
  end

  def textarea_field(form, field, text, height) do
    warning = error_tag(form, field) |> Enum.at(0)

    c(:form_field, :textarea,
      form: form,
      field: field,
      text: text,
      warning: warning,
      height: height
    )
  end

  def hero_large(
        title,
        subtitle,
        illustration,
        bg_color \\ "bg-primary",
        text_color \\ "text-white"
      ) do
    c(:hero, :large,
      title: title,
      subtitle: subtitle,
      illustration: illustration,
      bg_color: bg_color,
      text_color: text_color
    )
  end

  def hero_small(title, illustration, bg_color \\ "bg-primary", text_color \\ "text-white") do
    c(:hero, :small,
      title: title,
      illustration: illustration,
      bg_color: bg_color,
      text_color: text_color
    )
  end

  def primary_button(label, path, method \\ :get, bg_color \\ "bg-grey1", width \\ "w-none") do
    c(:custom_button, :primary,
      label: label,
      method: method,
      path: path,
      color: bg_color,
      width: width
    )
  end

  def primary_icon_button(label, icon, path, bg_color \\ "bg-grey1") do
    c(:custom_button, :primary_icon,
      label: label,
      method: :get,
      icon: icon,
      path: path,
      color: bg_color
    )
  end

  def secondary_button(
        label,
        path,
        method \\ :get,
        text_color \\ "text-primary",
        border_color \\ "border-primary",
        width \\ "w-none"
      ) do
    c(:custom_button, :secondary,
      label: label,
      method: method,
      path: path,
      text_color: text_color,
      border_color: border_color,
      width: width
    )
  end

  def delete_button(
    label,
    path,
    opts \\ []
  ) do
    opts =
      opts
      |> Keyword.put_new(:label, label)
      |> Keyword.put_new(:path, path)
      |> Keyword.put_new(:color, "bg-delete")
      |> Keyword.put_new(:width, "w-full")
      |> Keyword.put_new(:method, :delete)

    c(:custom_button, :delete, opts)
  end

  def submit_button_wide(label, bg_color \\ "bg-grey1") do
    width = "w-full"
    c(:custom_button, :submit, label: label, color: bg_color, width: width)
  end

  def submit_button_small(label, bg_color \\ "bg-grey1") do
    width = "p-4"
    c(:custom_button, :submit, label: label, color: bg_color, width: width)
  end

  def link_button(label, path, method \\ :get) do
    csrf_token = Plug.CSRFProtection.get_csrf_token_for(path)
    c(:custom_button, :link, label: label, path: path, method: method, csrf_token: csrf_token)
  end

  def menu_button(label, path, method \\ "get") do
    csrf_token = Plug.CSRFProtection.get_csrf_token_for(path)
    c(:custom_button, :menu, label: label, path: path, method: method, csrf_token: csrf_token)
  end

  def language_button(conn, locale) do
    c(:custom_button, :language, conn: conn, locale: locale)
  end

  def back_button(conn) do
    c(:custom_button, :back, conn: conn)
  end

  def warning(message) do
    c(:message, :warning, message: message)
  end

  defp view(name) do
    module_name = Naming.camelize("#{name}") <> "View"
    Module.concat(Components, module_name)
  end

  def primary_bullit(conn, label) do
    c(:bullit, :primary, conn: conn, label: label)
  end

  def primary_cta(title, button_label, button_path) do
    bg_color = "bg-grey1"
    button_bg_color = "bg-white"
    button_text_color = "text-primary"

    c(:card, :cta,
      title: title,
      button_label: button_label,
      button_path: button_path,
      bg_color: bg_color,
      button_bg_color: button_bg_color,
      button_text_color: button_text_color
    )
  end

  def primary_study_card(conn, study, button_label) do
    button_path = Routes.study_path(conn, :show, study.id)
    title_color = "text-white"
    description_color = "text-grey4"
    bg_color = "bg-grey1"
    button_bg_color = "bg-white"
    button_text_color = "text-primary"

    c(:card, :study,
      study: study,
      button_label: button_label,
      button_path: button_path,
      bg_color: bg_color,
      button_bg_color: button_bg_color,
      button_text_color: button_text_color,
      title_color: title_color,
      description_color: description_color
    )
  end

  def secondary_study_card(conn, study, button_label) do
    button_path = Routes.study_path(conn, :show, study.id)
    title_color = "text-grey1"
    description_color = "text-grey2"
    bg_color = "bg-grey6"
    button_bg_color = "bg-grey1"
    button_text_color = "text-white"

    c(:card, :study,
      study: study,
      button_label: button_label,
      button_path: button_path,
      bg_color: bg_color,
      button_bg_color: button_bg_color,
      button_text_color: button_text_color,
      title_color: title_color,
      description_color: description_color
    )
  end

  def usp_card(title, description, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:title, title)
      |> Keyword.put_new(:description, description)
      |> Keyword.put_new(:title_color, "text-grey1")
      |> Keyword.put_new(:description_color, "text-grey2")
      |> Keyword.put_new(:bg_color, "bg-grey6")

    c(:card, :usp, opts)
  end

  def button_card(conn, title, path, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:conn, conn)
      |> Keyword.put_new(:title, title)
      |> Keyword.put_new(:path, path)

    c(:card, :button, opts)
  end

  def footer(conn, opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:conn, conn)

    c(:footer, :default, opts)
  end

  defp template(name) when is_atom(name) do
    "#{name}.html"
  end
end
