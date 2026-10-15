defmodule Systems.Crew.Selector do
  defmacro __using__({model, key}) do
    quote bind_quoted: [model: model, key: key] do
      @enforce_keys [:query]

      @type t :: %__MODULE__{query: Ecto.Query.t()}
      defstruct [:query]

      require Ecto.Query

      defmacro where(selector, binding \\ [], expr) do
        quote do
          unquote(selector).update(
            Ecto.Query.where(
              unquote(selector).query,
              unquote(binding),
              unquote(expr)
            )
          )
        end
      end

      defmacro join(selector, qual, binding, expr, opts) do
        quote do
          unquote(selector).update(
            Ecto.Query.join(
              unquote(selector).query,
              unquote(qual),
              unquote(binding),
              unquote(expr),
              unquote(opts)
            )
          )
        end
      end

      defmacro join(selector, qual, assoc, key \\ unquote(key)) do
        quote do
          unquote(selector).update(
            Ecto.Query.join(
              unquote(selector).query,
              :inner,
              [{unquote(key), b}],
              _ in assoc(b, unquote(assoc)),
              as: unquote(assoc)
            )
          )
        end
      end

      defmacro select(selector, binding, expr) do
        quote do
          unquote(selector).update(
            Ecto.Query.select(
              unquote(selector).query,
              unquote(binding),
              unquote(expr)
            )
          )
        end
      end

      defmacro select(selector, field) do
        quote do
          unquote(selector).update(
            Ecto.Query.select(
              unquote(selector).query,
              [member: m],
              m.unquote(field)
            )
          )
        end
      end

      defmacro pin(value) do
        quote do: ^unquote(value)
      end

      def update(selector, %Ecto.Query{} = query) do
        %__MODULE__{selector | query: query}
      end

      def new() do
        %__MODULE__{query: Ecto.Query.from(x in unquote(model), as: unquote(key))}
      end

      # def new(graph) do
      #   query = Ecto.Query.from(x in unquote(model), as: unquote(key))
      #   %__MODULE__{query: parse_graph(query, graph)}
      # end

      def maybe(%__MODULE__{} = selector, expr, f) when is_function(f, 1) do
        if expr do
          selector.update(f.(selector.query))
        else
          selector
        end
      end

      def maybe(%__MODULE__{} = selector, expr, f) when is_function(f, 2) do
        if expr do
          selector.update(f.(selector.query, expr))
        else
          selector
        end
      end

      defimpl Ecto.Queryable do
        def to_query(%{query: query}), do: query
      end

      # def join(%__MODULE__{} = selector, binding, assoc, opts \\ []) when is_atom(binding) and is_atom(assoc) do
      #   type = Keyword.get(opts, :type, :inner)
      #   append(selector, &Ecto.Query.join(&1, type, [{:binding, b}], _ in assoc(b, assoc), as: assoc))
      # end

      def authorize(%__MODULE__{} = selector, binding, role) when is_atom(role) do
        authorize(selector, binding, [role])
      end

      def authorize(%__MODULE__{} = selector, binding, role_list) when is_list(role_list) do
        auth_node_binding = String.to_atom("#{binding}_#{:auth_node}")
        assignments_binding = String.to_atom("#{auth_node_binding}_#{:role_assignments}")

        selector
        |> join(:inner, [{^binding, b}], _ in assoc(b, :auth_node), as: ^auth_node_binding)
        |> join(:inner, [{^auth_node_binding, b}], _ in assoc(b, :role_assignments),
          as: ^assignments_binding
        )
        |> where([{^assignments_binding, b}], b.role in ^role_list)
      end

      def authorize(%__MODULE__{} = selector, binding, role, %{} = user_ids_queryable) do
        assignments_binding = String.to_atom("#{binding}_auth_node_role_assignments")

        authorize(selector, binding, role)
        |> where([{^assignments_binding, b}], b.principal_id in subquery(user_ids_queryable))
      end

      def authorize(%__MODULE__{} = selector, binding, role, user_ids) when is_list(user_ids) do
        assignments_binding = String.to_atom("#{binding}_auth_node_role_assignments")

        authorize(selector, binding, role)
        |> where([{^assignments_binding, b}], b.principal_id in ^user_ids)
      end

      def authorize(%__MODULE__{} = selector, binding, role, user_id) do
        authorize(selector, binding, role, [user_id])
      end

      def select_ids(%__MODULE__{} = selector) do
        select(selector, [{unquote(key), b}], b.id)
      end
    end
  end
end
