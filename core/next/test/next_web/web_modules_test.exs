defmodule NextWeb.WebModulesTest do
  use ExUnit.Case, async: true

  @blocks ~w(utility ui pixel html live_component live_component_fabric live_view_fabric
             routed_live_view embedded_live_view modal_live_view live_features channel router)a

  describe "the SaaS web modules" do
    for web <- [NextWeb, MicaSaasWeb], block <- @blocks do
      test "#{inspect(web)}.#{block} is MicaWeb's block with its own paths" do
        assert apply(unquote(web), unquote(block), []) ==
                 with_paths(apply(MicaWeb, unquote(block), []), unquote(web))
      end
    end

    for web <- [NextWeb, MicaSaasWeb] do
      test "#{inspect(web)}.controller is MicaWeb's block with its own paths" do
        opts = [formats: [:json]]
        assert unquote(web).controller(opts) == with_paths(MicaWeb.controller(opts), unquote(web))
      end

      test "#{inspect(web)} verifies ~p against the router it is given" do
        assert {:use, _, [{:__aliases__, _, [:Phoenix, :VerifiedRoutes]}, opts]} =
                 unquote(web).verified_routes()

        assert opts[:router] == MicaWeb.Router
        assert opts[:endpoint] == MicaWeb.Endpoint
      end
    end
  end

  test "MicaWeb builds its paths with ~m, not with a router" do
    assert {:use, _, [{:__aliases__, _, [:MicaWeb, :Path]}]} = MicaWeb.verified_routes()
  end

  # MicaWeb's block with its `~m` replaced by the SaaS's verified `~p`.
  defp with_paths(block, web) do
    mica_paths = MicaWeb.verified_routes()
    Macro.prewalk(block, &if(&1 == mica_paths, do: web.verified_routes(), else: &1))
  end
end
