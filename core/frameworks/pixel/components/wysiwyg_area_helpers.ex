defmodule Frameworks.Pixel.WysiwygAreaHelpers do
  @moduledoc false
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.HTML, only: [raw: 1]

  alias Frameworks.Pixel.TrixPostProcessor
  alias Phoenix.LiveView.Socket

  @callback handle_wysiwyg_update(Socket.t()) :: Socket.t()

  defmacro __using__(_opts) do
    quote do
      @behaviour Frameworks.Pixel.WysiwygAreaHelpers

      import Frameworks.Pixel.Form
      import Frameworks.Pixel.WysiwygAreaHelpers, only: [post_process: 1]

      @impl true
      def handle_event("save_wysiwyg", %{"_target" => [input_name]} = params, socket) do
        content =
          params
          |> Map.get(input_name)
          |> post_process()

        field_name =
          input_name
          |> String.replace_suffix("_input", "")
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

  def post_process(content) do
    TrixPostProcessor.add_target_blank(content)
  end

  def render_wysiwyg(wysiwyg_text) do
    raw(wysiwyg_text)
  end
end
