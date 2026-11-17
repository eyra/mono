defmodule MicaSaas.Systems.Feldspar.LocalFSTest do
  use ExUnit.Case, async: true

  alias Systems.Feldspar.LocalFS

  describe "get_public_url/1" do
    test "returns URL" do
      id = Ecto.UUID.generate()
      url = LocalFS.get_public_url(id)
      uri = URI.parse(url)
      assert String.contains?(uri.path, id)
    end
  end
end
