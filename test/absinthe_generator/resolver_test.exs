defmodule AbsintheGenerator.ResolverTest do
  use ExUnit.Case, async: true

  @test_struct %AbsintheGenerator.Resolver{
    app_name: "MyApp",
    resolver_name: "cats",
    resolver_functions: [
      """
      def find(params, _) do
        EctoSchemas.Felines.find_cats(params)
      end
      """,

      """
      def all(params, _) do
        EctoSchemas.Felines.all_cats(params)
      end
      """
    ]
  }

  @expected_output String.replace_suffix("""
  defmodule MyApp.Resolvers.Cats do
    @moduledoc false

    def find(params, _) do
      EctoSchemas.Felines.find_cats(params)
    end

    def all(params, _) do
      EctoSchemas.Felines.all_cats(params)
    end
  end
  """, "\n", "")

  describe "&run/1" do
    test "generates a fully setup resolver file" do
      assert Enum.join(AbsintheGenerator.Resolver.run(@test_struct)) === @expected_output
    end
  end
end
