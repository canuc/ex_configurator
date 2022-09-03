defmodule ExConfiguratorTest do
  use ExUnit.Case
  doctest ExConfigurator

  test "should define function value and set to one" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, :handler, value: 1)

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest1 do
            use ExConfigurator, app: :test_app, name: :handler
          end

          MyModTest1.get_value()
        end
      )

    assert result == 1
  end

  test "should override the app in config" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app_update, :handler, value: [handler: 1])

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest2 do
            use ExConfigurator, app: :test_app_update, name: :handler
          end

          [MyModTest2.get_value(), MyModTest2.get_value_handler()]
        end
      )

    assert result == [[handler: 1], 1]
  end

  test "should be able to define a map - without traversing in" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, :handler, simple: %{what_do_you_call_it: "some_string"})

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest3 do
            use ExConfigurator, app: :test_app, name: :handler
          end

          MyModTest3.get_simple()
        end
      )

    assert result == %{what_do_you_call_it: "some_string"}
  end

  test "should be able to read application env at runtime" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, :handler, value: "some_string")

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest4 do
            use ExConfigurator, name: :handler
          end

          Application.put_env(:test_app, :handler, value: "other_string")

          MyModTest4.get_env_value()
        end
      )

    assert result == "other_string"
  end

  test "should define function get_value_handler" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, :handler, value: [handler: 1])

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest5 do
            use ExConfigurator, app: :test_app, name: :handler
          end

          [MyModTest5.get_value(), MyModTest5.get_value_handler()]
        end
      )

    assert result == [[handler: 1], 1]
  end

  test "should be able to reference by module name" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, MyModTest6, value: 1)

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest6 do
            use ExConfigurator
          end

          MyModTest6.get_env_value()
        end
      )

    assert result == 1
  end

  test "should define function get_env_value_handler" do
    Application.put_env(:ex_configurator, :application, :test_app)

    Application.put_env(:test_app, :handler, value: [handler: 1])

    {result, _binding} =
      Code.eval_quoted(
        quote do
          defmodule MyModTest7 do
            use ExConfigurator, app: :test_app, name: :handler
          end

          Application.put_env(:test_app, :handler, value: [handler: 2])

          [MyModTest7.get_value_handler(), MyModTest7.get_env_value_handler()]
        end
      )

    assert result == [1, 2]
  end
end
