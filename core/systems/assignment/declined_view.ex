defmodule Systems.Assignment.DeclinedView do
  use CoreWeb, :live_component

  import CoreWeb.Gettext

  @impl true
  def update(_, socket) do
    body = dgettext("eyra-assignment", "declined_view.body")

    {
      :ok,
      socket |> assign(body: body)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="flex flex-col gap-2 items-center w-full h-full">
          <div class="wysiwyg">
            <%= raw @body %>
          </div>
        </div>
      </div>
    """
  end
end
