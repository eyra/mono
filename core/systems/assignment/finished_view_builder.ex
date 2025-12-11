defmodule Systems.Assignment.FinishedViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{Assignment, Affiliate}

  def view_model(%{affiliate: affiliate} = assignment, %{current_user: user}) do
    declined? = Assignment.Private.no_consent?(assignment, user.id)

    redirect_url =
      case Affiliate.Public.redirect_url(affiliate, user) do
        {:ok, url} -> url
        {:error, _} -> nil
      end

    title =
      if declined? do
        dgettext("eyra-assignment", "finished_view.title.declined")
      else
        dgettext("eyra-assignment", "finished_view.title")
      end

    body =
      cond do
        declined? and redirect_url ->
          dgettext("eyra-assignment", "finished_view.body.declined.redirect")

        declined? ->
          dgettext("eyra-assignment", "finished_view.body.declined")

        redirect_url ->
          dgettext("eyra-assignment", "finished_view.body.redirect")

        true ->
          dgettext("eyra-assignment", "finished_view.body")
      end

    illustration =
      if not declined? and is_nil(redirect_url) do
        "/images/illustrations/finished.svg"
      else
        nil
      end

    back_button = %{
      action: %{type: :send, event: "retry"},
      face: %{
        type: :plain,
        icon: :back,
        icon_align: :left,
        label: dgettext("eyra-assignment", "back.button")
      }
    }

    continue_button =
      if redirect_url do
        %{
          action: %{type: :http_get, to: redirect_url},
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "redirect.button")
          }
        }
      else
        nil
      end

    %{
      title: title,
      body: body,
      illustration: illustration,
      back_button: back_button,
      continue_button: continue_button
    }
  end
end
