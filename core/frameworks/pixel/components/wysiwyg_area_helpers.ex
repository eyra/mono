defmodule Frameworks.Pixel.WysiwygAreaHelpers do
  alias Frameworks.Pixel.TrixPostProcessor

  import Phoenix.Component, only: [assign: 3]

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

  def post_process(content) do
    TrixPostProcessor.add_target_blank(content)
  end
end
