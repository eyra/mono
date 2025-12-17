defmodule Systems.Assignment.FinishedViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{Assignment, Affiliate}

  def view_model(%{affiliate: affiliate} = assignment, %{current_user: user}) do
    declined? = Assignment.Private.no_consent?(assignment, user.id)
    platform_name = get_platform_name(affiliate)
    redirect_url = get_redirect_url(affiliate, user)

    %{
      title: build_title(declined?),
      body: build_body(declined?, redirect_url, platform_name),
      illustration: build_illustration(declined?, redirect_url),
      back_button: build_back_button(),
      continue_button: build_continue_button(redirect_url)
    }
  end

  defp get_redirect_url(affiliate, user) do
    case Affiliate.Public.redirect_url(affiliate, user) do
      {:ok, url} -> url
      {:error, _} -> nil
    end
  end

  defp build_title(true = _declined?),
    do: dgettext("eyra-assignment", "finished_view.title.declined")

  defp build_title(false = _declined?),
    do: dgettext("eyra-assignment", "finished_view.title")

  defp build_body(declined?, redirect_url, platform_name) do
    has_redirect? = not is_nil(redirect_url)
    has_platform? = not is_nil(platform_name)

    cond do
      declined? and has_redirect? and has_platform? ->
        dgettext("eyra-assignment", "finished_view.body.declined.redirect.platform",
          platform: platform_name
        )

      declined? and has_redirect? ->
        dgettext("eyra-assignment", "finished_view.body.declined.redirect")

      declined? ->
        dgettext("eyra-assignment", "finished_view.body.declined")

      has_redirect? and has_platform? ->
        dgettext("eyra-assignment", "finished_view.body.redirect.platform",
          platform: platform_name
        )

      has_redirect? ->
        dgettext("eyra-assignment", "finished_view.body.redirect")

      true ->
        dgettext("eyra-assignment", "finished_view.body")
    end
  end

  defp build_illustration(false = _declined?, nil = _redirect_url),
    do: "/images/illustrations/finished.svg"

  defp build_illustration(_declined?, _redirect_url), do: nil

  defp build_back_button do
    %{
      action: %{type: :send, event: "retry"},
      face: %{
        type: :plain,
        icon: :back,
        icon_align: :left,
        label: dgettext("eyra-assignment", "back.button")
      }
    }
  end

  defp build_continue_button(nil = _redirect_url), do: nil

  defp build_continue_button(redirect_url) do
    %{
      action: %{type: :http_get, to: redirect_url},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "redirect.button")
      }
    }
  end

  defp get_platform_name(%{platform_name: name}) when is_binary(name) and name != "", do: name
  defp get_platform_name(_), do: nil
end
