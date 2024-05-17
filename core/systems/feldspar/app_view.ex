defmodule Systems.Feldspar.AppView do
  use CoreWeb, :live_component

  @impl true
  def update(%{key: key, url: url, locale: locale}, socket) do
    {:ok, socket |> assign(key: key, url: url, locale: locale)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="pt-4 md:pt-20 pl-4 md:pl-20 pr-4 pb-4">
        <%!-- Ensure that updates don't alter the hierarchy in front of the iframe.
        Changing the preceding siblings of the iframe would result in a reload of the iframe
        due to Morphdom (https://github.com/patrick-steele-idem/morphdom/issues/200).
          --%>
        <div phx-update="ignore" id={@key} phx-hook="FeldsparApp" data-locale={@locale} data-src={@url}>
          <iframe class="w-full outline-none"></iframe>
        </div>
      </div>
    """
  end
end
