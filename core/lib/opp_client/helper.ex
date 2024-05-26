defmodule OPPClient.Helper do
  @path_param_re ~r/\{\{(.*)\}\}/

  defmacro __using__(_opts) do
    quote do
      def get(client, path, params \\ [])
      def post(client, path, params \\ [])

      import OPPClient.Helper
    end
  end

  defmacro def_req(method, path, schema \\ []) do
    response_schema_name = get_response_schema_name(method, path)
    positional_args = get_positional_args(path)

    schema = get_finalized_schema(schema, method, positional_args)

    response_schema_path = Path.join(__DIR__, "#{response_schema_name}.json")

    response_schema =
      response_schema_path
      |> File.read!()
      |> Jason.decode!()
      |> ExJsonSchema.Schema.resolve()

    quote do
      # Ensures recompilation on schema file changes
      @external_resource unquote(Path.relative_to_cwd(response_schema_path))

      def unquote(method)(client, unquote(path), params) do
        unquote(__MODULE__).request(
          client,
          unquote(method),
          unquote(path),
          unquote(positional_args),
          unquote(Macro.escape(schema)),
          unquote(Macro.escape(response_schema)),
          params
        )
      end
    end
  end

  def request(client, method, path, positional_args, schema, response_json_schema, params) do
    path_with_args =
      Regex.replace(@path_param_re, path, fn _, param ->
        Keyword.fetch!(params, String.to_atom(param))
      end)

    {idempotency_key, body_params} =
      params
      |> Keyword.drop(positional_args)
      |> Keyword.pop(:idempotency_key, [])

    request =
      %{client | method: method}
      |> Req.Request.put_header("idempotency-key", idempotency_key)

    with {:ok, _} <- NimbleOptions.validate(params, schema),
         {:ok, response} <-
           Req.request(request,
             url: path_with_args,
             json: Map.new(body_params)
           ),
         :ok <- ExJsonSchema.Validator.validate(response_json_schema, response.body) do
      {:ok, response.body}
    end
  end

  def get_response_schema_name(method, path) do
    name =
      String.trim(path, "/")
      |> String.replace(@path_param_re, "by_\\1", global: true)
      |> String.replace("/", "_")

    "#{method}_#{name}" |> String.to_atom()
  end

  def get_positional_args(path) do
    Regex.scan(@path_param_re, path)
    |> Enum.map(fn [_, param] -> String.to_atom(param) end)
  end

  def get_finalized_schema(schema, method, positional_args) do
    schema =
      schema ++ Enum.map(positional_args, fn arg -> {arg, [type: :string, required: true]} end)

    # Require idempotency key on mutation
    if method == :post do
      [{:idempotency_key, [type: :string, required: true]} | schema]
    else
      schema
    end
  end
end
