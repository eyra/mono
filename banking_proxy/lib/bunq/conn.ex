defmodule Bunq.Conn do
  defstruct endpoint: nil,
            private_key: nil,
            api_key: nil,
            installation_token: nil,
            device_id: nil,
            server_public_key: nil,
            session_token: nil,
            company_id: nil,
            account_id: nil
end
