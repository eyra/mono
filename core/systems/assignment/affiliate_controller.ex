defmodule Systems.Assignment.AffiliateController do
  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  alias Systems.Assignment
  alias Systems.Affiliate

  require Logger

  @id_valid_regex ~r/^[A-Za-z0-9_-]+$/
  @id_max_lenght 64

  def create(conn, %{"id" => id} = params) do
    assignment = Assignment.Public.get!(id, [:info, :crew, :auth_node])

    if tester?(assignment, conn) do
      if invalid_id?(params) do
        forbidden(conn)
      else
        start_tester(conn, params, assignment)
      end
    else
      cond do
        invalid_id?(params) -> forbidden(conn)
        offline?(assignment) -> service_unavailable(conn)
        true -> start_participant(conn, params, assignment)
      end
    end
  end

  @doc """
  Controller level callback for handling path parameter type validation errors.
  """
  def validation_error_callback(conn, _errors) do
    conn
    |> put_status(:not_found)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"400")
    |> halt()
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

  defp start_tester(conn, params, assignment) do
    conn
    |> obtain_instance(assignment)
    |> redirect(to: path(params))
  end

  defp start_participant(conn, params, %{affiliate: affiliate} = assignment) do
    participant_id = get_participant(params)
    %{user: user} = affiliate_user = Affiliate.Public.obtain_user(participant_id, affiliate)

    conn
    |> assign(:current_user, user)
    |> authorize_user(assignment)
    |> ensure_user_info(params, assignment, affiliate_user)
    |> obtain_instance(assignment)
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

  defp ensure_user_info(conn, params, %{affiliate: affiliate} = assignment, affiliate_user) do
    info = strip_query_string(params)
    user_info = Affiliate.Public.obtain_user_info!(affiliate, affiliate_user, info)

    Logger.debug(
      "Obtained user info for assignment #{assignment.id} and user #{affiliate_user.user.id}; info=#{inspect(user_info)}"
    )

    conn
  end

  defp obtain_instance(%{assigns: %{current_user: user}} = conn, assignment) do
    instance = Assignment.Public.obtain_instance!(assignment, user)
    Logger.debug("Starting session for assignment #{assignment.id} with instance #{instance.id}")
    conn
  end

  # Param Mappings

  defp get_participant(%{"p" => participant}), do: participant
  defp get_participant(%{"participant" => participant}), do: participant

  defp get_participant(_), do: nil

  defp strip_query_string(params) do
    params
    |> Map.delete("id")
    |> Map.delete("p")
    |> Map.delete("participant")
  end
end
