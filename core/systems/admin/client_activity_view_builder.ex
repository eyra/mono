defmodule Systems.Admin.ClientActivityViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin ClientActivityView.

  Only builds data for system admins (`is_admin?: true`).

  Three levels, picked by the assigns:
  - no `client_id`: clients with their assignment count
  - `client_id`: that client's assignments
  - `assignment_id`: the assignment's details and team

  Who the client of an assignment is, is decided in `Systems.Admin.Queries.assignment_client_query/0`.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias CoreWeb.UI.Timestamp
  alias Systems.Account
  alias Systems.Admin

  def view_model(_model, %{is_admin?: true} = assigns) do
    active_filters = Map.get(assigns, :active_filters, [])
    today = Map.get(assigns, :today, Date.utc_today())

    level =
      build_level(
        Map.get(assigns, :client_id),
        Map.get(assigns, :assignment_id),
        active_filters,
        today
      )

    %{
      title: dgettext("eyra-admin", "client_activity.title"),
      title_count: title_count(level),
      filter_label: dgettext("eyra-org", "filter.label"),
      filter_labels: Admin.ClientActivityFilters.labels(active_filters),
      filter_hint: dgettext("eyra-admin", "client_activity.filter.hint"),
      level: level
    }
  end

  # Only system admins may see client activity, whoever embeds this view.
  def view_model(_model, _assigns) do
    %{
      title: dgettext("eyra-admin", "client_activity.title"),
      title_count: nil,
      filter_label: nil,
      filter_labels: [],
      filter_hint: nil,
      level: %{type: :forbidden}
    }
  end

  defp title_count(%{type: :clients, count: count}), do: count
  defp title_count(_level), do: nil

  defp build_level(client_id, assignment_id, filters, today) when not is_nil(assignment_id) do
    case Admin.Public.get_client_assignment(assignment_id) do
      nil -> build_level(client_id, nil, filters, today)
      details -> build_assignment_level(details)
    end
  end

  defp build_level(client_id, nil, filters, today) when not is_nil(client_id) do
    case Admin.Public.get_client(client_id) do
      nil -> build_clients_level(filters, today)
      client -> build_client_level(client, filters, today)
    end
  end

  defp build_level(nil, nil, filters, today), do: build_clients_level(filters, today)

  defp build_clients_level(filters, today) do
    clients =
      filters
      |> Admin.Public.list_client_activity(today)
      |> Enum.map(&build_client_item/1)

    %{
      type: :clients,
      count: length(clients),
      clients: clients,
      head: %{
        client: dgettext("eyra-admin", "client_activity.head.client"),
        email: dgettext("eyra-admin", "client_activity.head.email"),
        assignments: dgettext("eyra-admin", "client_activity.head.assignments")
      },
      empty: dgettext("eyra-admin", "client_activity.clients.empty")
    }
  end

  defp build_client_item(%{
         client: %Account.User{id: id, displayname: name, email: email},
         assignment_count: count
       }) do
    %{id: id, name: name, email: email, assignment_count: count}
  end

  defp build_client_level(
         %Account.User{id: id, displayname: name, email: email},
         filters,
         today
       ) do
    assignments =
      id
      |> Admin.Public.list_client_assignments(filters, today)
      |> Enum.map(&build_assignment_item/1)

    %{
      type: :client,
      client: %{id: id, name: name, email: email},
      back_label: dgettext("eyra-admin", "client_activity.back.clients"),
      count: length(assignments),
      assignments: assignments,
      head: %{
        name: dgettext("eyra-admin", "client_activity.head.assignment"),
        status: dgettext("eyra-admin", "client_activity.head.status"),
        created: dgettext("eyra-admin", "client_activity.head.created")
      },
      empty: dgettext("eyra-admin", "client_activity.assignments.empty")
    }
  end

  defp build_assignment_item(%{
         assignment: %{id: id, status: status, inserted_at: inserted_at},
         name: name
       }) do
    %{
      id: id,
      name: name,
      status: status_label(status),
      created: Timestamp.format_date!(inserted_at)
    }
  end

  defp build_assignment_level(%{
         assignment: %{id: id, status: status, inserted_at: inserted_at, updated_at: updated_at},
         name: name,
         client: %Account.User{displayname: client_name, email: client_email} = client,
         team: team
       }) do
    %{
      type: :assignment,
      back_label: dgettext("eyra-admin", "client_activity.back.assignments", client: client_name),
      name: name,
      details: [
        detail(dgettext("eyra-admin", "client_activity.detail.id"), "#{id}"),
        detail(
          dgettext("eyra-admin", "client_activity.detail.client"),
          "#{client_name} (#{client_email})"
        ),
        detail(dgettext("eyra-admin", "client_activity.head.status"), status_label(status)),
        detail(
          dgettext("eyra-admin", "client_activity.head.created"),
          Timestamp.format_date!(inserted_at)
        ),
        detail(
          dgettext("eyra-admin", "client_activity.detail.updated"),
          Timestamp.format_date!(updated_at)
        )
      ],
      team_title: dgettext("eyra-admin", "client_activity.team.title"),
      team: Enum.map(team, &build_team_member(&1, client))
    }
  end

  defp detail(label, value), do: %{label: label, value: value}

  defp build_team_member(
         %Account.User{id: id, displayname: name, email: email},
         %Account.User{id: client_id}
       ) do
    %{
      id: id,
      name: name,
      email: email,
      client?: id == client_id,
      client_label: dgettext("eyra-admin", "client_activity.team.client")
    }
  end

  defp status_label(:concept), do: dgettext("eyra-project", "label.concept")
  defp status_label(:online), do: dgettext("eyra-project", "label.online")
  defp status_label(:offline), do: dgettext("eyra-project", "label.offline")
  defp status_label(:idle), do: dgettext("eyra-project", "label.idle")
  defp status_label(status), do: "#{status}"
end
