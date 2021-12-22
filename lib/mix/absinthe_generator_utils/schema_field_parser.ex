defmodule Mix.AbsintheGeneratorUtils.SchemaFieldParser do
  def parse_fields(fields) do
    Enum.map(fields, &parse_field/1)
  end

  def parse_field(field) do
    case String.split(field, ":") do
      [field_name, return_type | field_or_resolver_or_middleware] ->
        {
          resolver_module_function,
          args,
          pre_middleware,
          post_middleware
        } = parse_args_resolver_and_middleware(field_or_resolver_or_middleware)

        %AbsintheGenerator.Schema.Field{
          name: field_name,
          return_type: return_type,
          resolver_module_function: resolver_module_function,
          arguments: args,
          pre_middleware: pre_middleware,
          post_middleware: post_middleware
        }
    end
  end

  defp parse_args_resolver_and_middleware(field_or_resolver_or_middleware) do
    {resolver_function, args_and_middleware} = Enum.split_with(field_or_resolver_or_middleware, &(&1 =~ "."))

    {pre_middleware, args, post_middleware} = args_and_middleware
      |> Enum.chunk_every(2)
      |> Enum.reduce({[], [], []}, fn
        (["middleware", middleware], {pre_middleware, args, post_middleware}) when args !== [] ->
          {pre_middleware, args, post_middleware ++ [middleware]}

        (["middleware", middleware], {pre_middleware, args, post_middleware}) ->
          {pre_middleware ++ [middleware], args, post_middleware}

        ([arg_name, arg_type], {pre_middleware, args, post_middleware}) ->
          argument = %AbsintheGenerator.Schema.Field.Argument{
            name: arg_name,
            type: arg_type
          }

          {pre_middleware, args ++ [argument], post_middleware}
      end)

    {resolver_function, args, pre_middleware, post_middleware}
  end
end
