defmodule Systems.Affiliate.Controller do
  use Systems.Affiliate.Constants

  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  import Systems.Account.UserAuth, only: [log_in_user_without_redirect: 2]

  alias Systems.Assignment
  alias Systems.Affiliate

  require Logger

  @id_valid_regex ~r/^[A-Za-z0-9_-]+$/
  @id_max_lenght 64

  def create(conn, %{"sqid" => sqid} = params) do
    case numbers(sqid) do
      {:ok, numbers} ->
        start(conn, params, numbers)

      {:error, error} ->
        Logger.error("#{inspect(error)}, someone is trying to hack us, params=#{inspect(params)}")
        forbidden(conn)
    end
  end

  defp numbers(sqid) do
    numbers = Affiliate.Sqids.decode!(sqid)

    if Affiliate.Sqids.encode!(numbers) == sqid do
      {:ok, numbers}
    else
      {:error, "Invalid sqid #{sqid}"}
    end
  end

  defp start(conn, params, [@annotation_resource_id, assignment_id]) do
    assignment =
      Assignment.Public.get!(assignment_id, [:info, :affiliate, :workflow, :crew, :auth_node])

    cond do
      # Preview mode: tester with ?p=preview from CMS
      preview?(params) and tester?(assignment, conn) ->
        start_tester(conn, params, assignment)

      # Valid participant ID -> start as participant
      valid_id?(get_participant(params)) ->
        if offline?(assignment) do
          service_unavailable(conn)
        else
          start_participant(conn, params, assignment)
        end

      # Invalid ID and not a tester -> forbidden
      true ->
        Logger.error("Access denied invalid id #{inspect(params)}")
        forbidden(conn)
    end
  end

  defp start(conn, params, numbers) do
    Logger.error("Access denied params=#{inspect(params)} numbers=#{inspect(numbers)}")
    forbidden(conn)
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

  defp preview?(params), do: get_participant(params) == "preview"

  defp offline?(%{status: status}) do
    status != :online
  end

  def valid_id?(nil), do: false
  def valid_id?("participant_id"), do: false

  def valid_id?(id) do
    String.length(id) <= @id_max_lenght and Regex.match?(@id_valid_regex, id)
  end

  defp start_tester(conn, params, %{affiliate: affiliate} = assignment) do
    redirect_url = Affiliate.Public.get_redirect_url(affiliate)

    conn
    |> obtain_instance(assignment)
    |> add_panel_info(get_participant(params), redirect_url)
    |> redirect(to: path(assignment))
  end

  defp start_participant(conn, params, %{affiliate: affiliate} = assignment) do
    participant_id = get_participant(params)
    %{user: user} = affiliate_user = Affiliate.Public.obtain_user!(participant_id, affiliate)

    conn
    |> assign(:current_user, user)
    |> log_in_user_without_redirect(user)
    |> authorize_user(assignment)
    |> ensure_user_info(params, affiliate_user)
    |> obtain_instance(assignment)
    |> add_panel_info_for_participant(params, affiliate, affiliate_user)
    |> redirect(to: path(assignment))
  end

  defp path(%{id: id}), do: "/assignment/#{id}"

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

  defp ensure_user_info(conn, params, affiliate_user) do
    info = strip_query_string(params)
    user_info = Affiliate.Public.obtain_user_info!(affiliate_user, info)

    Logger.debug(
      "Obtained user info for affiliate user #{affiliate_user.id}; info=#{inspect(user_info)}"
    )

    conn
  end

  defp obtain_instance(%{assigns: %{current_user: user}} = conn, assignment) do
    instance = Assignment.Public.obtain_instance!(assignment, user)
    Logger.debug("Starting session for assignment #{assignment.id} with instance #{instance.id}")
    conn
  end

  defp add_panel_info(conn, participant, redirect_url) do
    panel_info = %{
      panel: :affiliate,
      redirect_url: redirect_url,
      participant: participant
    }

    conn |> put_session(:panel_info, panel_info)
  end

  defp add_panel_info_for_participant(conn, params, affiliate, affiliate_user) do
    participant = get_participant(params)
    redirect_url = get_merged_redirect_url(affiliate, affiliate_user)
    add_panel_info(conn, participant, redirect_url)
  end

  defp get_merged_redirect_url(affiliate, affiliate_user) do
    case Affiliate.Public.redirect_url(affiliate, affiliate_user) do
      {:ok, url} -> url
      {:error, _} -> nil
    end
  end

  # Param Mappings

  defp get_participant(%{"p" => participant}), do: participant

  defp get_participant(_), do: nil

  defp strip_query_string(params) do
    params
    |> Map.delete("sqid")
  end
end
