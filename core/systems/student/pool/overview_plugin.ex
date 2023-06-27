defmodule Systems.Student.Pool.OverviewPlugin do
  use CoreWeb, :live_component

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Grid

  alias Systems.{
    Pool
  }

  # Initial update
  @impl true
  def update(%{id: id, user: user}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        user: user
      )
      |> update_pools()
    }
  end

  defp update_pools(%{assigns: %{user: user, myself: myself}} = socket) do
    pools =
      Pool.Public.list_by_director(
        "student",
        Pool.Model.preload_graph([:org, :participants, :submissions, :auth_node])
      )
      |> Enum.filter(&is_owner?(&1, user))

    pool_items = Enum.map(pools, &to_view_model(&1, myself))

    socket |> assign(pools: pools, pool_items: pool_items)
  end

  defp get_pool(socket, pool_id) when is_binary(pool_id) do
    get_pool(socket, String.to_integer(pool_id))
  end

  defp get_pool(%{assigns: %{pools: pools}} = _socket, pool_id) when is_integer(pool_id) do
    Enum.find(pools, &(&1.id == pool_id))
  end

  defp is_owner?(entity, user) do
    Core.Authorization.user_has_role?(user, entity, :owner)
  end

  @impl true
  def handle_event("archive", %{"item" => pool_id}, socket) do
    socket
    |> get_pool(pool_id)
    |> Pool.Public.update!(%{archived: true})

    {:noreply, socket |> update_pools()}
  end

  @impl true
  def handle_event("restore", %{"item" => pool_id}, socket) do
    socket
    |> get_pool(pool_id)
    |> Pool.Public.update!(%{archived: false})

    {:noreply, socket |> update_pools()}
  end

  defp to_view_model(%{id: id} = pool, target) do
    archived_action = archived_action(pool, target)
    share_action = share_action(pool)

    %{
      title: Pool.Model.title(pool),
      description: description(pool),
      tags: Pool.Model.namespace(pool),
      item: id,
      left_actions: [archived_action],
      right_actions: [share_action]
    }
  end

  defp archived_action(%{id: id, archived: true} = _pool, target) do
    %{
      action: %{type: :send, event: "restore", item: id, target: target},
      face: %{
        type: :label,
        label: dgettext("link-citizen", "overview.restore.button"),
        font: "text-subhead font-subhead",
        text_color: "text-primary",
        wrap: true
      }
    }
  end

  defp archived_action(%{id: id} = _pool, target) do
    %{
      action: %{type: :send, event: "archive", item: id, target: target},
      face: %{
        type: :label,
        label: dgettext("link-citizen", "overview.archive.button"),
        font: "text-subhead font-subhead",
        text_color: "text-delete",
        wrap: true
      }
    }
  end

  defp share_action(%{id: id} = _pool) do
    %{
      action: %{type: :send, event: "share", item: id},
      face: %{
        type: :label,
        label: dgettext("link-citizen", "overview.share.button"),
        font: "text-subhead font-subhead",
        text_color: "text-grey1",
        wrap: true
      }
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

  attr(:user, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Text.title2><%= dgettext("link-studentpool", "overview.plugin.title") %> <span class="text-primary"><%= Enum.count(@pool_items) %></span></Text.title2>
      <Grid.dynamic>
        <%= for pool_item <- @pool_items do %>
          <Pool.ItemView.normal {pool_item} />
        <% end %>
      </Grid.dynamic>
    </div>
    """
  end
end
