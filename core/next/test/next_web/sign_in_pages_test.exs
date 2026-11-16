defmodule NextWeb.SignInPagesTest do
  # Mica links to a SaaS's sign-in pages only through its `Mica.SaaS` callbacks
  # (d-0011). Each SaaS must name pages that its own router serves, from its
  # own override routes. Self's router is compiled in every build until
  # code-split, so it is checked here too.
  use ExUnit.Case, async: false
  use Mica.FeatureFlags.Test

  @saases [{Next.SaaS, NextWeb.Router}, {MicaSaas.SaaS, MicaSaasWeb.Router}]

  for {saas, router} <- @saases, otp <- [false, true] do
    describe "#{inspect(saas)} with otp #{otp}" do
      setup do
        set_feature_flag(:otp, unquote(otp))
        :ok
      end

      test "every sign-in page is a page of its router, from its own systems" do
        saas = unquote(saas)

        pages = [
          sign_in_page: saas.sign_in_page(),
          member_sign_in_page: saas.member_sign_in_page("/assignment/1"),
          sign_in_options_page: saas.sign_in_options_page(),
          creator_identify_page: saas.identify_page(:creator),
          participant_identify_page: saas.identify_page(:participant)
        ]

        for {callback, page} <- pages do
          assert served_by_saas?(unquote(router), "GET", page),
                 "#{callback} #{page} is no page of #{inspect(unquote(router))}"
        end
      end

      test "the session path takes the sign-in form and the sign-out" do
        path = unquote(saas).session_path()

        for verb <- ~w(POST DELETE) do
          assert served_by_saas?(unquote(router), verb, path),
                 "#{verb} #{path} is not served by #{inspect(unquote(router))}"
        end
      end
    end
  end

  test "Next sends participants back to the page they opened when codes are on" do
    set_feature_flag(:otp, true)

    assert Next.SaaS.member_sign_in_page("/assignment/1") ==
             "/user/auth/identify/participant?return_to=%2Fassignment%2F1"
  end

  # A route of the SaaS's own systems, not one of Mica's.
  defp served_by_saas?(router, verb, page) do
    %URI{path: path} = URI.parse(page)

    case Phoenix.Router.route_info(router, verb, path, "") do
      :error -> false
      route -> hd(Module.split(owner(route))) in ~w(Next MicaSaas)
    end
  end

  defp owner(%{phoenix_live_view: {live_view, _action, _opts, _session}}), do: live_view
  defp owner(%{plug: plug}), do: plug
end
