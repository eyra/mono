defmodule CoreWeb.Dependencies.ResolverTest do
  use ExUnit.Case, async: true

  alias CoreWeb.Dependencies.Resolver

  describe "resolve/2" do
    setup do
      map = %{
        adapter: {Plug.Cowboy.Conn},
        assigns: %{
          current_user: nil,
          flash: %{},
          live_module: CoreWeb.User.Signup
        },
        before_send: [],
        body_params: %{},
        cookies: %{
          "_link_key" =>
            "SFMyNTY.g3QAAAAEbQAAAAtfY3NyZl90b2tlbm0AAAAYT01TYmV4UmFzSGRnSjl5Qk45NDY4ckhFbQAAAAlsaW5rX2F1dGhtAAAAa1NGTXlOVFkuYkdsdWExODBPRGN5WldKa015MWxNRFpsTFRSallqWXRPRE0xWXkwMk1EYzNaVEkxTlRreU56QS5xNXN6Q1NFbXZLNndWRmxMUy1iTmZCYVFhR0VUNjFEMzFhOF93clBjWEpZbQAAAAZsb2NhbGVtAAAAAm5sbQAAAA1wYXRoX3Byb3ZpZGVyZAAbRWxpeGlyLkxpbmtXZWIuUGF0aFByb3ZpZGVy.kaz4jJpUKIM2IN39OOB9bmKieSG2ukSQMxc9vcyRFPo",
          "locale" => "nl"
        },
        endpoint: LinkWeb.Endpoint,
        halted: false,
        host: "localhost",
        method: "GET",
        owner: nil,
        params: %{},
        path_info: ["user", "signup"],
        path_params: %{},
        port: 4000,
        private: %{
          LinkWeb.Router => {[], %{}},
          :cldr_locale => %Cldr.LanguageTag{
            backend: CoreWeb.Cldr,
            canonical_locale_name: "nl-Latn-NL",
            cldr_locale_name: "nl",
            extensions: %{},
            gettext_locale_name: "nl",
            language: "nl",
            language_subtags: [],
            language_variant: nil,
            locale: %{},
            private_use: [],
            rbnf_locale_name: "nl",
            requested_locale_name: "nl",
            script: "Latn",
            territory: :NL,
            transform: %{}
          },
          :phoenix_endpoint => LinkWeb.Endpoint,
          :phoenix_flash => %{},
          :phoenix_format => "html",
          :phoenix_layout => false,
          :phoenix_live_view => {CoreWeb.User.Signup, [action: nil, router: LinkWeb.Router]},
          :phoenix_request_logger => {"request_logger", "request_logger"},
          :phoenix_root_layout => {CoreWeb.LayoutView, :root},
          :phoenix_router => LinkWeb.Router,
          :phoenix_template => "template.html",
          :phoenix_view => Phoenix.LiveView.Static,
          :plug_session => %{
            "_csrf_token" => "OMSbexRasHdgJ9yBN9468rHE",
            "link_auth" =>
              "SFMyNTY.bGlua180ODcyZWJkMy1lMDZlLTRjYjYtODM1Yy02MDc3ZTI1NTkyNzA.q5szCSEmvK6wVFlLS-bNfBaQaGET61D31a8_wrPcXJY",
            "locale" => "nl",
            "path_provider1" => LinkWeb.PathProvider
          },
          :connect_info => %{
            :session => %{
              "locale" => "nl",
              "path_provider2" => LinkWeb.PathProvider
            }
          },
          :plug_session_fetch => :done,
          :plug_session_info => :write
        },
        query_params: %{},
        query_string: "",
        remote_ip: {127, 0, 0, 1},
        req_cookies: %{
          "_link_key" =>
            "SFMyNTY.g3QAAAAEbQAAAAtfY3NyZl90b2tlbm0AAAAYT01TYmV4UmFzSGRnSjl5Qk45NDY4ckhFbQAAAAlsaW5rX2F1dGhtAAAAa1NGTXlOVFkuYkdsdWExODBPRGN5WldKa015MWxNRFpsTFRSallqWXRPRE0xWXkwMk1EYzNaVEkxTlRreU56QS5xNXN6Q1NFbXZLNndWRmxMUy1iTmZCYVFhR0VUNjFEMzFhOF93clBjWEpZbQAAAAZsb2NhbGVtAAAAAm5sbQAAAA1wYXRoX3Byb3ZpZGVyZAAbRWxpeGlyLkxpbmtXZWIuUGF0aFByb3ZpZGVy.kaz4jJpUKIM2IN39OOB9bmKieSG2ukSQMxc9vcyRFPo",
          "locale" => "nl"
        },
        req_headers: [
          {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"},
          {"accept-encoding", "gzip, deflate"},
          {"accept-language", "en-us"},
          {"connection", "keep-alive"},
          {"cookie",
           "_link_key=SFMyNTY.g3QAAAAEbQAAAAtfY3NyZl90b2tlbm0AAAAYT01TYmV4UmFzSGRnSjl5Qk45NDY4ckhFbQAAAAlsaW5rX2F1dGhtAAAAa1NGTXlOVFkuYkdsdWExODBPRGN5WldKa015MWxNRFpsTFRSallqWXRPRE0xWXkwMk1EYzNaVEkxTlRreU56QS5xNXN6Q1NFbXZLNndWRmxMUy1iTmZCYVFhR0VUNjFEMzFhOF93clBjWEpZbQAAAAZsb2NhbGVtAAAAAm5sbQAAAA1wYXRoX3Byb3ZpZGVyZAAbRWxpeGlyLkxpbmtXZWIuUGF0aFByb3ZpZGVy.kaz4jJpUKIM2IN39OOB9bmKieSG2ukSQMxc9vcyRFPo; locale=nl"},
          {"host", "localhost:4000"},
          {"referer", "http://localhost:4000/user/signin"},
          {"upgrade-insecure-requests", "1"},
          {"user-agent",
           "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15"}
        ],
        request_path: "/user/signup",
        resp_body: nil,
        resp_cookies: %{},
        resp_headers: [
          {"cache-control",
           "max-age=0, no-cache, no-store, must-revalidate, post-check=0, pre-check=0"},
          {"x-request-id", "FmqCFe3mG1f6qnkAAAbH"},
          {"x-frame-options", "SAMEORIGIN"},
          {"x-xss-protection", "1; mode=block"},
          {"x-content-type-options", "nosniff"},
          {"x-download-options", "noopen"},
          {"x-permitted-cross-domain-policies", "none"},
          {"cross-origin-window-policy", "deny"},
          {"vary", "x-requested-with"}
        ],
        scheme: :http,
        script_name: [],
        secret_key_base: :...,
        state: :unset,
        status: nil
      }

      %{map: map}
    end

    test "resolve dependency in root", %{map: map} do
      endpoint = Resolver.resolve(map, :endpoint)
      assert endpoint === LinkWeb.Endpoint
    end

    test "resolve dependency in private subpath", %{map: map} do
      endpoint = Resolver.resolve(map, :phoenix_endpoint)
      assert endpoint === LinkWeb.Endpoint
    end

    test "resolve dependency in private/plug_session subpath", %{map: map} do
      path_provider = Resolver.resolve(map, "path_provider1")
      assert path_provider === LinkWeb.PathProvider
    end

    test "resolve dependency in private/connect_info/session subpath", %{map: map} do
      path_provider = Resolver.resolve(map, "path_provider2")
      assert path_provider === LinkWeb.PathProvider
    end

    test "resolve non-existing dependency", %{map: map} do
      non_existing = Resolver.resolve(map, :non_existing)
      assert non_existing === :error
    end
  end
end
