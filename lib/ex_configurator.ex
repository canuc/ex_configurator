defmodule ExConfigurator do
  @moduledoc ~S"""

  # ExConfigurator

  A simple code generator that reduces the amount of env var retrieval in your app.

  ## Usage:

  It will allow you to simply setup:

    defmodule SomeModule do
      use ExConfigurator, :some_module

    end

  and any configs that are defined as:

    config :your_app, :some_module, a: 1, b:2

  Will autogenerate 2 getters for each element in the keyword list.

  * First - `SomeModule.get_a()/0` - Compile time. This will return 1 in the above example.
    It will generate a function that will return the compile time value.

  * Second - Runtime value. `SomeModule.get_env_a()/0` - This will return 1 in the above example.
    But if changed by a runtime config or a environment based config, the new value will be used.

  NOTE: You are probably looking for the second and not the first function **wink**

  ### Configuration

  To configure you must add the some config to your application:

    config :ex_configurator, application: :your_app

  Please replace :your_app with your app name.

  ### Complex Usage

  Nested keyword lists will create env vars for the top level and sub any nested config.

  For the following

    defmodule SomeNestedModule do
      use ExConfigurator, :some_module

    end

  with any configs that are defined as:

    config :your_app, :some_module, keys: [ infura: "asdfsdf", twilio: "234234" ]

  The following functions will be generated:

  * `SomeModule.get_env_keys()/0` = [ infura: "asdfsdf", twilio: "234234" ] - changes if updated during runtime
  * `SomeModule.get_keys()/0` = [ infura: "asdfsdf", twilio: "234234" ]
  * `SomeModule.get_env_keys_infura()/0` = "asdfsdf" - changes if updated during runtime
  * `SomeModule.get_keys_infura(()/0` = "asdfsdf"
  * `SomeModule.get_env_keys_twilio()/0` = "234234" - changes if updated during runtime
  * `SomeModule.get_keys_twilio(()/0` = "234234"

  This gives lots of flexibility.

  ## Special forms

  There are some special cases you might want to use this:

  If a compile time config is set to a tuple starting with `:system` of form: {:system, :integer | :string, "MY_ENV", 3434}

  then when calling `SomeModule.get_keys/0` the replaced method will lookup the system environment variable: "MY_ENV" and cast it to
  either string or integer value.
  """

  require Logger

  def handle_config(application, path, config_name, var, submodule) when is_struct(var) do
    quoted = generate_config_function(application, path, config_name, var, submodule)

    sub_quoted =
      for {inner_config, struct_val} <- var do
        handle_config(application, path ++ [config_name], inner_config, struct_val, submodule)
      end

    [quoted | sub_quoted]
  end

  def handle_config(application, path, config_name, var, submodule) when is_list(var) do
    quoted = generate_config_function(application, path, config_name, var, submodule)

    sub_quoted =
      for {inner_config, var} <- var do
        handle_config(application, path ++ [config_name], inner_config, var, submodule)
      end

    [quoted | sub_quoted]
  end

  def handle_config(application, path, config_name, var, submodule),
    do: generate_config_function(application, path, config_name, var, submodule)

  def generate_config_function(_application, _path, "", _var, _submodule), do: :noop

  def generate_config_function(application, path, config_name, var, submodule) do
    filtered_path = Enum.filter(path, &(&1 != "")) ++ [config_name]

    path_name =
      filtered_path
      |> Enum.join("_")

    generate_config_function_inner(application, path_name, var, submodule, filtered_path)
  end

  def clean_default_int(int) when is_binary(int), do: int
  def clean_default_int(int) when is_integer(int), do: Integer.to_string(int)

  def clean_defualt_string(string), do: to_string(string)

  def generate_config_function_inner(
        _application,
        path_name,
        {:system, :integer, name, default_val},
        _submodule,
        _path
      )
      when is_binary(name) do
    quote do
      def unquote(:"get_#{path_name}")() do
        {default_int, rest} =
          unquote(name)
          |> System.get_env(unquote(clean_default_int(default_val)))
          |> Integer.parse()

        default_int
      end
    end
  end

  def generate_config_function_inner(
        _application,
        path_name,
        {:system, :string, name, default_val},
        _submodule,
        _path
      )
      when is_binary(name) do
    quote do
      def unquote(:"get_#{path_name}")() do
        {default_int, rest} =
          unquote(name)
          |> System.get_env(unquote(clean_defualt_string(default_val)))
          |> to_string()

        default_int
      end
    end
  end

  def generate_config_function_inner(application, path_name, var, submodule, path)
      when is_list(var) do
    quote do
      def unquote(:"get_#{path_name}")() do
        unquote(var |> Enum.map(&Macro.escape/1))
      end

      def unquote(:"get_env_#{path_name}")() do
        Enum.reduce(
          unquote(path |> Enum.map(&Macro.escape/1)),
          Application.get_env(unquote(application), unquote(submodule), []),
          fn x, acc ->
            case acc do
              subj when is_map(subj) -> Map.get(subj, x)
              [{_key, _value} | _rest] = subj -> Keyword.get(subj, x)
              subj when is_list(subj) -> subj
            end
          end
        )
      end
    end
  end

  def generate_config_function_inner(application, path_name, var, submodule, path) do
    quote do
      def unquote(:"get_#{path_name}")(), do: unquote(Macro.escape(var))

      def unquote(:"get_env_#{path_name}")() do
        Enum.reduce(
          unquote(path |> Enum.map(&Macro.escape/1)),
          Application.get_env(unquote(application), unquote(submodule), []),
          fn x, acc ->
            case acc do
              subj when is_map(subj) -> Map.get(subj, x)
              subj when is_list(subj) -> Keyword.get(subj, x)
            end
          end
        )
      end
    end
  end

  @spec get_application_arg(any) :: atom | nil
  def get_application_arg([{:app, application} | _rest]) when is_atom(application),
    do: application

  def get_application_arg([_current | rest]), do: get_application_arg(rest)
  def get_application_arg(_), do: nil

  @spec app_or_env(any) :: atom | nil
  def app_or_env(args) do
    case get_application_arg(args) do
      nil -> Application.get_env(:ex_configurator, :application, nil)
      app when is_atom(app) -> app
    end
  end

  @spec get_alias(atom(), atom() | keyword()) :: atom()
  def get_alias(_caller, name) when is_atom(name), do: name
  def get_alias(_caller, [{:name, name} | _rest]) when is_atom(name), do: name
  def get_alias(caller, [_first | rest]), do: get_alias(caller, rest)
  def get_alias(caller, _), do: caller

  defmacro __using__(args \\ nil) do
    app = app_or_env(args)
    submodule = get_alias(__CALLER__.module, args)
    configs = Application.get_env(app, submodule, [])
    handle_config(app, [], "", configs, submodule)
  end
end
