defmodule Systems.Feldspar.AppView do
  use CoreWeb, :html

  attr(:url, :string, required: true)

  def app_view(assigns) do
    ~H"""
      <div class="flex flex-col w-full h-full">
        <%!-- Ensure that updates don't alter the hierarchy in front of the iframe.
        Changing the preceding siblings of the iframe would result in a reload of the iframe
        due to Morphdom (https://github.com/patrick-steele-idem/morphdom/issues/200).
          --%>
        <div class="w-full h-full" phx-update="ignore"  id="web-app-frame" phx-hook="FeldsparApp" data-src={@url}>
          <iframe class="w-full h-full"></iframe>
        </div>
      </div>
    """
  end
end
