defmodule Core.SurfConext.UserTest do
  use ExUnit.Case, async: false
  alias Core.SurfConext.User

  describe "changeset/2" do
    setup do
      conf = Application.get_env(:core, Core.SurfConext, [])

      on_exit(fn ->
        Application.put_env(:core, Core.SurfConext, conf)
      end)

      {:ok, conf: conf}
    end

    test "can limit to configured schac_home_organization", %{conf: conf} do
      Application.put_env(
        :core,
        Core.SurfConext,
        Keyword.put(conf, :limit_schac_home_organization, "my-org")
      )

      changeset =
        User.register_changeset(%User{}, %{sub: "tst", schac_home_organization: "wrong-org"})

      refute changeset.valid?
    end

    test "allow any schac_home_organization when no filter is set" do
      changeset =
        User.register_changeset(%User{}, %{
          email: "test@student.vu.nl",
          sub: "tst",
          schac_home_organization: "some-org"
        })

      assert changeset.valid?
    end
  end
end
