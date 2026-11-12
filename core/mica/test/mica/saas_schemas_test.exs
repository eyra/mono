defmodule Mica.SaaSSchemasTest.System do
  use Mica.System
end

defmodule Mica.SaaSSchemasTest.AssignmentRef do
  use Ecto.Schema

  schema "assignments" do
    belongs_to(:info, Systems.Assignment.InfoModel)
    belongs_to(:auth_node, Mica.Authorization.Node)
  end
end

defmodule Mica.SaaSSchemasTest do
  use Mica.DataCase, async: true

  alias Mica.Factories
  alias Mica.Repo
  alias Mica.SaaS
  alias Mica.SaaSSchemasTest.AssignmentRef
  alias Systems.Assignment

  # A second application in the composition, as Next is one after code-split.
  @app :mica_saas_schemas_test

  setup_all do
    :ok =
      :application.load(
        {:application, @app,
         [
           description: ~c"second application in the composition",
           vsn: ~c"0.0.0",
           modules: [Mica.SaaSSchemasTest.System, AssignmentRef],
           registered: [],
           applications: [:kernel, :stdlib]
         ]}
      )

    on_exit(fn -> :application.unload(@app) end)
  end

  describe "composition_apps/2" do
    test "is Mica's application alone while everything is in one application" do
      assert SaaS.composition_apps(SaaS.module(), SaaS.systems()) == [:mica]
    end

    test "adds the application of a system from another application" do
      systems = SaaS.systems() ++ [Mica.SaaSSchemasTest.System]
      assert SaaS.composition_apps(SaaS.module(), systems) == [:mica, @app]
    end
  end

  describe "schemas/0" do
    test "is the schemas of Mica's application while everything is in one application" do
      assert SaaS.schemas() == SaaS.collect_schemas([:mica])
    end
  end

  describe "collect_schemas/1" do
    test "collects the schemas of every application" do
      schemas = SaaS.collect_schemas([:mica, @app])

      assert AssignmentRef in schemas
      assert Assignment.InfoModel in schemas
      refute Mica.SaaSSchemasTest.System in schemas
    end
  end

  describe "orphan?/2" do
    test "sees a reference from a schema of another application" do
      %{info: info} = Factories.insert!(:assignment, %{})
      # Assignment.Model is Mica's own reference to the info; only the other one remains.
      ignore = [Assignment.Model]

      assert Repo.orphan?(info, schemas: SaaS.collect_schemas([:mica]), ignore: ignore)
      refute Repo.orphan?(info, schemas: SaaS.collect_schemas([:mica, @app]), ignore: ignore)
    end
  end

  describe "Mica.Authorization.entities/1" do
    test "lists a schema of another application that owns an auth node" do
      refute AssignmentRef in Mica.Authorization.entities(SaaS.collect_schemas([:mica]))
      assert AssignmentRef in Mica.Authorization.entities(SaaS.collect_schemas([:mica, @app]))
    end
  end
end
