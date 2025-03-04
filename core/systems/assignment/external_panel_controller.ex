defmodule Systems.Assignment.ExternalPanelController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  alias Systems.Assignment

  require Logger

  @id_valid_regex ~r/^[A-Za-z0-9_-]+$/
  @id_max_lenght 64

  def create(conn, %{"id" => id, "entry" => _} = params) do
    assignment = Assignment.Public.get!(id, [:info, :crew, :auth_node])

    Logger.warning("[ExternalPanelController] create: #{inspect(params)}")

    if tester?(assignment, conn) do
      if invalid_id?(params) do
        forbidden(conn)
      else
        start_tester(conn, params)
      end
    else
      cond do
        invalid_id?(params) -> forbidden(conn)
        has_no_access?(assignment, params) -> forbidden(conn)
        offline?(assignment) -> service_unavailable(conn)
        true -> start_participant(assignment, conn, params)
      end
    end
  end

  defp tester?(assignment, %{assigns: %{current_user: %{} = user}}) do
    Assignment.Public.tester?(assignment, user)
  end

  defp tester?(_, _), do: false

  defp offline?(%{status: status}) do
    status != :online
  end

  defp invalid_id?(%{} = params) do
    id = get_participant(params)
    invalid_id?(id)
  end

  defp invalid_id?(id) do
    not valid_id?(id)
  end

  def valid_id?(nil), do: false

  def valid_id?(id) do
    String.length(id) <= @id_max_lenght and Regex.match?(@id_valid_regex, id)
  end

  # FIXME: This is a temporary solution to allow embeds to work https://github.com/eyra/mono/issues/997
  defp has_no_access?(_, %{"embed" => "true"}), do: false

  defp has_no_access?(%{external_panel: external_panel}, params) do
    external_panel = Atom.to_string(external_panel)
    external_panel != get_panel(params)
  end

  defp start_tester(conn, params) do
    conn
    |> add_panel_info(params)
    |> redirect(to: path(params))
  end

  defp start_participant(%{external_panel: external_panel} = assignment, conn, params) do
    participant_id = get_participant(params)

    conn
    |> ExternalSignIn.sign_in(external_panel, participant_id)
    |> authorize_user(assignment)
    |> add_panel_info(params)
    |> redirect(to: path(params))
  end

  defp path(%{"id" => id}), do: "/assignment/#{id}"

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"403")
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"503")
  end

  defp authorize_user(%{assigns: %{current_user: user}} = conn, assignment) do
    Assignment.Public.add_participant!(assignment, user)
    conn
  end

  defp add_panel_info(conn, params) do
    panel_info = %{
      panel: get_panel(params),
      embedded?: embedded?(params),
      participant: get_participant(params),
      query_string: params
    }

    conn |> put_session(:panel_info, panel_info)
  end

  # Param Mappings

  defp get_panel(%{"entry" => "participate"}), do: "generic"
  defp get_panel(%{"entry" => entry}), do: entry

  defp get_participant(%{"respondent" => respondent}), do: respondent
  defp get_participant(%{"participant" => participant}), do: participant
  defp get_participant(_), do: nil

  defp embedded?(%{"entry" => "liss"}), do: true
  defp embedded?(%{"embed" => "true"}), do: true
  defp embedded?(_), do: false
end
