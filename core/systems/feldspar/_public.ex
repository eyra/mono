defmodule Systems.Feldspar.Public do
  import Systems.Feldspar.Internal, only: [get_backend: 0]

  def store(zip_file) do
    get_backend().store(zip_file)
  end

  def get_public_url(id) do
    get_backend().get_public_url(id)
  end

  def remove(id) do
    get_backend().remove(id)
  end
end
