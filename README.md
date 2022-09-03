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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_configurator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_configurator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_configurator>.
