defmodule Systems.DataDonation.DonateTaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data_donation_donate_tasks" do
    timestamps()
  end

  @fields ~w()a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
  end
end
