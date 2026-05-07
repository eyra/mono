defmodule Frameworks.Pixel.FileSelector do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.LoadingSpinner
  alias Frameworks.Pixel.Button

  attr(:id, :string, required: true)
  attr(:filename, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, required: true)
  attr(:uploads, :map, required: true)
  attr(:replace_button, :string, required: true)
  attr(:select_button, :map, required: true)
  attr(:file_key, :atom, default: :file)
  attr(:background_color, :string, default: "bg-transparent")
  attr(:target, :any, required: true)

  slot(:inner_block)

  def file_selector(assigns) do
    button_label =
      if assigns[:filename] do
        assigns[:replace_button]
      else
        assigns[:select_button]
      end

    upload_in_progress =
      case assigns[:uploads][:file].entries do
        [first_entry | _] -> first_entry.progress != 100
        _ -> false
      end

    assigns =
      assign(assigns, %{upload_in_progress: upload_in_progress, button_label: button_label})

    ~H"""
      <.form id={"#{@id}_file_selector_form"} for={%{}} phx-change="change" phx-target={@target} >
        <%= if @label do %>
          <Text.form_field_label id={"#{@id}_label"} ><%= @label %></Text.form_field_label>
          <.spacing value="XXS" />
        <% end %>

        <div class={"flex flex-col border-grey4 border-2 rounded pl-6 pr-6 #{@background_color}"}>
          <div class="flex flex-row items-center h-file-selector">
            <div class="flex-grow">
              <%= if @filename do %>
                <Text.body_large color="text-grey1"><%= @filename %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>

            <div>
              <%= if @upload_in_progress do %>
                <%= if @uploads[:file].entries do %>
                  <LoadingSpinner.progress_spinner progress={Enum.at(@uploads[@file_key].entries, 0).progress} />
                <% end %>
              <% else %>
              <label for={@uploads.file.ref}>
                <Button.Face.primary label={@button_label} bg_color="bg-tertiary" text_color="text-grey1" />
              </label>
              <% end %>
            </div>

          </div>

          <%= render_slot(@inner_block) %>

        </div>
        <div class="hidden">
          <.live_file_input upload={@uploads.file} />
        </div>

      </.form>
    """
  end
end
