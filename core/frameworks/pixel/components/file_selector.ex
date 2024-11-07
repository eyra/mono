defmodule Frameworks.Pixel.Components.FileSelector do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.LoadingSpinner

  attr(:id, :string, required: true)
  attr(:filename, :string, default: nil)
  attr(:label, :string, default: nil)
  attr(:placeholder, :string, required: true)
  attr(:uploads, :map, required: true)
  attr(:replace_button, :string, required: true)
  attr(:select_button, :map, required: true)
  attr(:file_key, :atom, default: :file)

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

          <div>
            <%= if @upload_in_progress do %>
              <%= if @uploads[:file].entries do %>
                <LoadingSpinner.progress_spinner progress={Enum.at(@uploads[@file_key].entries, 0).progress} />
              <% end %>
            <% else %>
            <%!-- This button is hardcoded and not dynamic because this is a very specific use-case where we want a label that looks like a button --%>
            <label for={@uploads.file.ref}>
              <div class="cursor-pointer pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 bg-tertiary text-grey1">
                <%= @button_label %>
              </div>
            </label>
            <% end %>
          </div>
          </div>
          <div class="hidden">
            <.live_file_input upload={@uploads.file} />
          </div>
        </div>
      </.form>
    """
  end
end
