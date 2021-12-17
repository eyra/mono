defmodule Bunq.Cursor do
  @derive Jason.Encoder
  defstruct future_url: nil,
            newer_url: nil,
            older_url: nil,
            has_more?: false
end
