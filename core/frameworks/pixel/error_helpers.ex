defmodule Frameworks.Pixel.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.Tag

  @doc """
  Checkss if there are errors.
  """
  def show_errors?(form) do
    form
    |> Map.get(:options, [])
    |> Keyword.get(:"data-show-errors", true)
  end

  @doc """
  Checkss if there are errors.
  """
  def has_error?(form, field) do
    form
    |> Map.get(:errors, [])
    |> Keyword.get_values(field)
    |> length > 0
  end

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      Tag.content_tag(:span, translate_error(error),
        class: "invalid-feedback",
        phx_feedback_for: Form.input_id(form, field)
      )
    end)
  end

  @doc """
  Generates message for inlined form input errors.
  """
  def error_message(%{errors: errors}, field) do
    case Keyword.get_values(errors, field) do
      [error | _] -> translate_error(error)
      _ -> nil
    end
  end

  @doc """
  Returnes border color in error, focus, and normal state.
  """
  def border_color(form, field) do
    if has_error?(form, field) do
      "border-warning focus:border-warning"
    else
      "border-grey3 focus:border-primary"
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(CoreWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CoreWeb.Gettext, "errors", msg, opts)
    end
  end
end
