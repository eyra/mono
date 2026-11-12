defmodule NextWeb.WebModulesTest do
  use ExUnit.Case, async: true

  @blocks ~w(utility ui pixel html live_component live_component_fabric live_view_fabric
             routed_live_view embedded_live_view modal_live_view live_features channel router)a

  describe "the SaaS web modules" do
    for web <- [NextWeb, MicaSaasWeb], block <- @blocks do
      test "#{inspect(web)}.#{block} is the same block as MicaWeb's" do
        assert apply(unquote(web), unquote(block), []) == apply(MicaWeb, unquote(block), [])
      end
    end

    for web <- [NextWeb, MicaSaasWeb] do
      test "#{inspect(web)}.controller is the same block as MicaWeb's" do
        opts = [formats: [:json]]
        assert unquote(web).controller(opts) == MicaWeb.controller(opts)
      end

      test "#{inspect(web)} verifies ~p against the router it is given" do
        assert {:use, _, [{:__aliases__, _, [:Phoenix, :VerifiedRoutes]}, opts]} =
                 unquote(web).verified_routes()

        assert opts[:router] == MicaWeb.Router
        assert opts[:endpoint] == MicaWeb.Endpoint
      end
    end
  end
end
