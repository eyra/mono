defmodule Systems.Assignment.DeclinedView do
  use CoreWeb, :live_component

  use Gettext, backend: CoreWeb.Gettext

  @impl true
  def update(_, socket) do
    body = dgettext("eyra-assignment", "declined_view.body")
    title = dgettext("eyra-assignment", "declined_view.title")

    {
      :ok,
      socket |> assign(body: body, title: title)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Text.title2><%= @title %></Text.title2>
        <div class="flex flex-col gap-2 items-center w-full h-full">
          <div class="wysiwyg">
            <%= raw @body %>
          </div>
        </div>
      </div>
    """
  end
end
