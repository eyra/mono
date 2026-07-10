defmodule Systems.Assignment.FinishedViewBuilder do
  use Gettext, backend: CoreWeb.Gettext
  use Core.FeatureFlags

  alias Systems.Assignment
  alias Systems.Affiliate
  alias Systems.Pool

  def view_model(
        %{affiliate: affiliate} = assignment,
        %{current_user: user, live_context: %{data: %{panel_info: panel_info}}} = assigns
      ) do
    declined? = Assignment.Private.no_consent?(assignment, user.id)
    platform_name = get_platform_name(affiliate)
    redirect_url = get_redirect_url(panel_info)
    runtime_config = runtime_config(assignment)
    submitting? = Map.get(assigns, :submitting, false)

    email_capture = build_email_capture(declined?, runtime_config, user, submitting?)

    %{
      title: build_title(declined?),
      body: build_body(declined?, redirect_url, platform_name),
      illustration: build_illustration(declined?, redirect_url),
      back_button: build_back_button(),
      continue_button: build_continue_button(redirect_url),
      email_capture: email_capture
    }
  end

  # Fallback when no panel_info (direct access without affiliate flow)
  def view_model(%{} = assignment, %{current_user: _user} = assigns) do
    view_model(assignment, Map.put(assigns, :live_context, %{data: %{panel_info: nil}}))
  end

  defp runtime_config(%{special: nil}), do: %Assignment.RuntimeConfig{}

  defp runtime_config(assignment) do
    template = Assignment.Private.get_template(assignment)
    Assignment.Template.runtime_config(template)
  end

  # The finished-page Panl block. States chosen by feature flags + Panl
  # membership + user type:
  #
  #   :panl off                            → no block
  #
  #   pre-launch (:panl on) — affiliate visitor only:
  #     already a Panl member              → email-capture submitted ack
  #     already sent an email sign-up      → email-capture submitted ack
  #     otherwise                          → email-capture form
  #
  #   post-launch (:panl_post_launch on) — any non-creator user:
  #     already a Panl member              → "Home" CTA
  #     affiliate synth account            → "Join Panl" CTA → auth flow
  #                                          (need to link a real email
  #                                          before joining)
  #     regular user (has a real email)    → "Join Panl" CTA → straight
  #                                          to `/pool/:slug/join`
  defp build_email_capture(true = _declined?, _runtime_config, _user, _submitting?), do: nil
  defp build_email_capture(_declined?, %{post_action: nil}, _user, _submitting?), do: nil

  defp build_email_capture(
         _declined?,
         %{post_action: {:add_to_pool, pool_slug} = action},
         user,
         submitting?
       ) do
    cond do
      not feature_enabled?(:panl) -> nil
      creator?(user) -> nil
      feature_enabled?(:panl_post_launch) -> build_post_launch_block(pool_slug, user)
      true -> build_pre_launch_block(action, pool_slug, user, submitting?)
    end
  end

  defp creator?(%{creator: true}), do: true
  defp creator?(_), do: false

  # Post-launch block — no affiliate gate. Show a CTA to anyone who
  # isn't already a Panl member.
  defp build_post_launch_block(pool_slug, user) do
    if Pool.Public.participant?(pool_slug, user) do
      build_home_cta()
    else
      build_join_cta(pool_slug, user)
    end
  end

  # Pre-launch block — affiliate-only (matches the pre-launch UX; a
  # regular user already has a real email, so there's nothing for the
  # email-capture form to collect).
  defp build_pre_launch_block(action, pool_slug, user, submitting?) do
    case Affiliate.Public.get_user(user) do
      {:ok, _affiliate_user} ->
        cond do
          Pool.Public.participant?(pool_slug, user) -> build_email_capture_submitted()
          EmailSignUp.get_by_user(user) != nil -> build_email_capture_submitted()
          true -> build_email_capture_form(action, submitting?)
        end

      {:error, :user_not_found} ->
        nil
    end
  end

  defp build_email_capture_form(action, submitting?) do
    %{
      action: action,
      title: dgettext("eyra-assignment", "email_capture.title"),
      body: dgettext("eyra-assignment", "email_capture.body"),
      email_label: dgettext("eyra-assignment", "email_capture.email.label"),
      submit_button: %{
        action: %{type: :submit},
        face: %{
          type: :primary,
          label: dgettext("eyra-assignment", "email_capture.submit.label"),
          loading: submitting?
        }
      }
    }
  end

  defp build_email_capture_submitted do
    %{
      title: dgettext("eyra-assignment", "email_capture.success.title"),
      body: dgettext("eyra-assignment", "email_capture.success.body")
    }
  end

  # Post-launch: user is not yet a Panl member. The affiliate synth
  # variant needs to collect + link a real email first, so we route them
  # through auth identify → verify → redeem (`return_to` steers them
  # into `/pool/:slug/join` after auth). A regular user already has a
  # real email, so we skip auth and go straight to the join gate.
  defp build_join_cta(pool_slug, user) do
    %{
      title: dgettext("eyra-assignment", "panl.cta.join.title"),
      body: dgettext("eyra-assignment", "panl.cta.join.body"),
      cta_button: %{
        action: %{type: :http_get, to: join_url(pool_slug, user)},
        face: %{
          type: :primary,
          label: dgettext("eyra-assignment", "panl.cta.join.button")
        }
      }
    }
  end

  defp join_url(pool_slug, user) do
    case Affiliate.Public.get_user(user) do
      {:ok, _affiliate_user} ->
        "/user/auth/identify?return_to=/pool/#{pool_slug}/join"

      _ ->
        "/pool/#{pool_slug}/join"
    end
  end

  # Post-launch: affiliate visitor is already a Panl member. Send them home;
  # the home page carries their wallet / rewards summary.
  defp build_home_cta do
    %{
      title: dgettext("eyra-assignment", "panl.cta.home.title"),
      body: dgettext("eyra-assignment", "panl.cta.home.body"),
      cta_button: %{
        action: %{type: :http_get, to: "/"},
        face: %{
          type: :primary,
          label: dgettext("eyra-assignment", "panl.cta.home.button")
        }
      }
    }
  end

  defp get_redirect_url(%{redirect_url: redirect_url}), do: redirect_url
  defp get_redirect_url(_), do: nil

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
