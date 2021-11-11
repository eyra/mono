defmodule Bunq.SetupCLI do
  @key_file "private_key.pem"

  def main(args) do
    {opts, parsed_args, _} =
      OptionParser.parse_head(args,
        strict: [sandbox: :boolean, help: :boolean, generate_api_key: :boolean]
      )

    process(Map.new(opts), parsed_args)
  end

  def process(%{help: true}, _) do
    IO.puts("""
    Run with the Bunq API key as an argument. Optionally
    provide the --sandbox switch to use the Bunq sandbox.

    Pass --generate-api-key to create a sandbox company.
    """)
  end

  def process(%{sandbox: true, generate_api_key: true} = opts, _) do
    IO.puts("Generating API key ...")

    %{api_key: api_key} =
      endpoint(opts)
      |> Bunq.API.create_conn("")
      |> Bunq.API.create_sandbox_company()

    process(%{opts | generate_api_key: false}, api_key)
  end

  def process(%{}, []) do
    IO.puts(:stderr, "The Bunq API key is a required argument")
  end

  def process(%{} = opts, api_key) when is_binary(api_key) do
    IO.puts("Generating private key...")
    private_key = Bunq.API.generate_key()
    private_pem = :public_key.pem_entry_encode(:RSAPrivateKey, private_key)
    key_pem = :public_key.pem_encode([private_pem])
    File.write!(@key_file, key_pem)
    IO.puts("Creating Bunq installation...")
    conn = Bunq.API.create_conn(endpoint(opts), private_key)

    %{installation_token: installation_token, device_id: device_id} =
      %{conn | api_key: api_key}
      |> Bunq.API.create_installation()
      |> Bunq.API.register_device()

    divider()
    IO.puts("Private key file:   #{@key_file}")
    IO.puts("API key:   #{api_key}")
    IO.puts("Installation token: #{installation_token}")
    IO.puts("Device id:          #{device_id}")
    divider()
  end

  defp endpoint(opts) do
    if Map.get(opts, :sandbox, false) do
      Bunq.API.sandbox_endpoint()
    else
      Bunq.API.production_endpoint()
    end
  end

  defp divider do
    IO.puts(Stream.cycle(["-", "="]) |> Enum.take(80) |> Enum.join())
  end
end
