defmodule Frameworks.Pixel.WysiwygAreaHelpers do
  alias Frameworks.Pixel.RichText

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.HTML, only: [raw: 1]

  @callback handle_wysiwyg_update(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Pixel.WysiwygAreaHelpers

      import Frameworks.Pixel.WysiwygAreaHelpers, only: [post_process: 1]
      import Frameworks.Pixel.Form

      @impl true
      def handle_event("save_wysiwyg", %{"_target" => [input_name]} = params, socket) do
        content =
          params
          |> Map.get(input_name)
          |> post_process()

        field_name =
          String.replace_suffix(input_name, "_input", "")
          |> String.to_existing_atom()

        {
          :noreply,
          socket
          |> assign(field_name, content)
          |> handle_wysiwyg_update()
        }
      end
    end
  end

  # Text over the limit isn't cleaned; the field's changeset refuses it.
  def post_process(content) do
    if RichText.too_large?(content), do: content, else: RichText.clean(content)
  end

  def render_wysiwyg(wysiwyg_text) do
    wysiwyg_text |> RichText.clean_stored() |> raw()
  end
end
