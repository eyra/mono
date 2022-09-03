defmodule Systems.Pool.OverviewPage do
  @moduledoc """
   The student overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pools
  use CoreWeb.UI.Responsive.Viewport

  import CoreWeb.Gettext

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias Frameworks.Pixel.Grid.DynamicGrid

  alias Systems.{
    Pool,
    Org
  }

  data(pools, :any)

  @impl true
  def handle_event("handle_pool_click", %{"item" => pool_id}, socket) do
    pool_id = String.to_integer(pool_id)
    promotion_path = Routes.live_path(socket, Systems.Pool.DetailPage, pool_id)
    {:noreply, push_redirect(socket, to: promotion_path)}
  end

  @impl true
  def mount(_params, _session, socket) do
    # FIXME POOLS: slect pools that current user has access to using auth permissions on org nodes
    pools =
      Org.Context.list_nodes(:scholar_course, ["vu", "sbe"], [])
      |> Pool.Context.list_by_orgs(Pool.Model.preload_graph([:org, :participants, :submissions]))
      |> Enum.map(&vm(&1))

    {
      :ok,
      socket |> assign(pools: pools)
    }
  end

  @impl true
  def handle_resize(socket) do
    socket |> update_menus()
  end

  defp vm(%{id: id} = pool) do
    %{
      title: Pool.Model.title(pool),
      description: description(pool),
      tags: Pool.Model.namespace(pool),
      item: id
    }
  end

  defp description(%{participants: participants, submissions: submissions}) do
    submissions = remove_concept_submissions(submissions)

    [
      "#{dgettext("link-studentpool", "participants.label")}: #{Enum.count(participants)}",
      "#{dgettext("link-studentpool", "campaigns.label")}: #{Enum.count(submissions)}"
    ]
    |> Enum.join("  |  ")
  end

  defp remove_concept_submissions(submissions) do
    submissions
    |> Enum.filter(&Pool.SubmissionModel.submitted?(&1))
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-studentpool", "overview.title")} menus={@menus}>
      <div id={:pool_overview} phx-hook="ViewportResize">
        <ContentArea>
          <MarginY id={:page_top} />
          <DynamicGrid>
            <div :for={pool <- @pools}>
              <Pool.ItemView {...pool} />
            </div>
          </DynamicGrid>
        </ContentArea>
      </div>
    </Workspace>
    """
  end
end
