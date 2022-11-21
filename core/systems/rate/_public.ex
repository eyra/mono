defmodule Systems.Rate.Public do
  alias CoreWeb.UI.Timestamp

  alias Systems.{
    Rate
  }

  def validate(ip, service, bandwidth)
      when is_binary(ip) and is_atom(service) and is_integer(bandwidth) do

    today = Timestamp.now() |> Timestamp.to_date() |> Timestamp.humanize_date()
    raw_key = "#{today}-#{ip}"
    key = :crypto.hash(:md5, raw_key) |> Base.encode16()

    Rate.LimitModel.get!(service)
    |> Rate.Private.validate(key, service, bandwidth)
  end

end
