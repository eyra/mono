defmodule Next.ArchplanRoutesAnnotatorTest do
  # archplan's router annotator (.archplan/annotators/) reads the routes of the
  # router its config names. Runs the annotator with that config, as archplan
  # does. Sets System.argv/1 while the script runs.
  use ExUnit.Case, async: false

  @moduletag :tmp_dir

  @config "../.archplan/annotators/phoenix-routes.json"
  @script "../.archplan/annotators/phoenix_routes.exs"

  test "the annotator reads the auth declarations of the configured router", %{tmp_dir: dir} do
    ctx = Path.join(dir, "ctx.json")
    out = Path.join(dir, "out.json")
    %{"params" => params} = @config |> File.read!() |> JSON.decode!()
    File.write!(ctx, JSON.encode!(%{"params" => params}))

    argv = System.argv()
    System.argv([ctx, out])

    try do
      Code.eval_file(@script)
    after
      System.argv(argv)
    end

    %{"declarations" => declarations} = out |> File.read!() |> JSON.decode!()
    names = Enum.map(declarations, & &1["target"]["name"])

    assert "mount" in names
    assert Enum.all?(declarations, &(&1["key"] == "auth"))
  end
end
