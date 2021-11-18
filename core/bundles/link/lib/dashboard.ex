defmodule Link.Dashboard do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :dashboard

  alias Systems.{
    Campaign
  }

  alias Frameworks.Utility.ViewModelBuilder

  alias CoreWeb.UI.ContentListItem
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Text.{Title2}
  alias Systems.NextAction

  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    content_items =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, __MODULE__, user, url_resolver(socket)))

    socket =
      socket
      |> update_menus()
      |> assign(content_items: content_items)
      |> assign(next_best_action: NextAction.Context.next_best_action(url_resolver(socket), user))

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-dashboard", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <div :if={{ @next_best_action }} class="mb-6 md:mb-10">
            <NextAction.HighlightView vm={{ @next_best_action }}/>
          </div>
          <Case value={{ Enum.count(@content_items) > 0 }} >
            <True>
              <Title2>
                {{ dgettext("link-dashboard", "recent-items.title") }}
              </Title2>
              <ContentListItem :for={{item <- @content_items}} vm={{item}} />
            </True>
            <False>
              <Empty
                title={{ dgettext("eyra-dashboard", "empty.title") }}
                body={{ dgettext("eyra-dashboard", "empty.description") }}
                illustration="items"
              />
            </False>
          </Case>
        </ContentArea>
      </Workspace>
    """
  end
end
