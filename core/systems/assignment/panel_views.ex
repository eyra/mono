defmodule Systems.Assignment.PanelViews do
  use CoreWeb, :html

  attr(:id, :string, required: true)
  attr(:uri_origin, :string, required: true)

  def default(%{assignment: %{id: id}, uri_origin: uri_origin} = assigns) do
    url = uri_origin <> ~p"/assignment/#{id}"
    assigns = assign(assigns, url: url)

    ~H"""
      <.url_view url={@url} />
    """
  end

  attr(:id, :string, required: true)
  attr(:uri_origin, :string, required: true)

  def liss(%{assignment: %{id: id}, uri_origin: uri_origin} = assigns) do
    url = uri_origin <> ~p"/assignment/#{id}"
    assigns = assign(assigns, url: url)

    ~H"""
      <.url_view url={@url} />
    """
  end

  attr(:url, :string, required: true)

  defp url_view(assigns) do
    ~H"""
      <div class="flex flex-row gap-6 items-center">
        <div class="flex-wrap">
          <Text.body_medium><span class="break-all"><%= @url %></span></Text.body_medium>
        </div>
        <div class="flex-wrap flex-shrink-0 mt-1">
          <div id="copy-redirect-url" class="cursor-pointer" phx-hook="Clipboard" data-text={@url}>
            <Button.Face.label_icon
              label={dgettext("eyra-ui", "copy.button")}
              icon={:clipboard_primary}
            />
          </div>
        </div>
      </div>
    """
  end
end
