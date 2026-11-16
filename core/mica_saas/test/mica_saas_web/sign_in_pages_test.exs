defmodule MicaSaasWeb.SignInPagesTest do
  # Mica links to a SaaS's sign-in pages only through its `Mica.SaaS` callbacks
  # (d-0011). Self must name pages of its own systems, which its router serves
  # and which render.
  use MicaSaasWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  # With sign-in codes off, these send visitors to the page with every way to sign in.
  @code_pages [:creator_identify_page, :participant_identify_page]

  defp pages do
    [
      sign_in_page: MicaSaas.SaaS.sign_in_page(),
      member_sign_in_page: MicaSaas.SaaS.member_sign_in_page("/assignment/1"),
      sign_in_options_page: MicaSaas.SaaS.sign_in_options_page(),
      creator_identify_page: MicaSaas.SaaS.identify_page(:creator),
      participant_identify_page: MicaSaas.SaaS.identify_page(:participant)
    ]
  end

  for otp <- [false, true] do
    describe "MicaSaas.SaaS with otp #{otp}" do
      setup do
        set_feature_flag(:otp, unquote(otp))
        :ok
      end

      test "every sign-in page is a page of its router, from its own systems" do
        for {callback, page} <- pages() do
          assert served_by_self?("GET", page),
                 "#{callback} #{page} is no page of MicaSaasWeb.Router"
        end
      end

      test "the session path takes the sign-in form and the sign-out" do
        path = MicaSaas.SaaS.session_path()

        for verb <- ~w(POST DELETE) do
          assert served_by_self?(verb, path),
                 "#{verb} #{path} is not served by MicaSaasWeb.Router"
        end
      end

      test "every sign-in page renders for a visitor" do
        for {callback, page} <- pages() do
          conn = get(MicaSaasWeb.ConnCase.build_conn(), page)

          if unquote(otp) or callback not in @code_pages do
            assert html_response(conn, 200) =~ "<html", "#{callback} #{page} does not render"
          else
            assert redirected_to(conn) == MicaSaas.SaaS.sign_in_options_page()
          end
        end
      end
    end
  end

  # A route of Self's own systems, not one of Mica's.
  defp served_by_self?(verb, page) do
    %URI{path: path} = URI.parse(page)

    case Phoenix.Router.route_info(MicaSaasWeb.Router, verb, path, "") do
      :error -> false
      %{phoenix_live_view: {live_view, _action, _opts, _session}} -> self_module?(live_view)
      %{plug: plug} -> self_module?(plug)
    end
  end

  defp self_module?(module), do: hd(Module.split(module)) == "MicaSaas"
end
