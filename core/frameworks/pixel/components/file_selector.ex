defmodule Frameworks.Pixel.Components.FileSelector do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  attr(:id, :string, required: true)
  attr(:filename, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, required: true)
  attr(:uploads, :map, required: true)
  attr(:replace_button, :string, required: true)
  attr(:select_button, :map, required: true)

  def file_selector(assigns) do
    ~H"""
      <.form id={"#{@id}_file_selector_form"} for={%{}} phx-change="change" phx-target="" >
        <%= if @label do %>
          <Text.form_field_label id={"#{@id}_label"} ><%= @label %></Text.form_field_label>
          <.spacing value="XXS" />
        <% end %>
        <div class="h-file-selector border-grey4 border-2 rounded pl-6 pr-6">
          <div class="flex flex-row items-center h-full">
            <div class="flex-grow">
              <%= if @filename do %>
                <Text.body_large color="text-grey1"><%= @filename %></Text.body_large>
              <% else %>
                <Text.body_large color="text-grey2"><%= @placeholder %></Text.body_large>
              <% end %>
            </div>
            <%= if @filename do %>
              <Button.primary_label label={@replace_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.file.ref} />
            <% else %>
              <Button.primary_label label={@select_button} bg_color="bg-tertiary" text_color="text-grey1" field={@uploads.file.ref} />
            <% end %>
          </div>
          <div class="hidden">
            <.live_file_input upload={@uploads.file} />
          </div>
        </div>
      </.form>
    """
  end
end
