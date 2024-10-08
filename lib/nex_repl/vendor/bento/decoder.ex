defmodule NexREPL.Vendor.Bento.Decoder do
  @moduledoc """
  Useful wrapper for `Bento.Parser`.
  """

  alias NexREPL.Vendor.Bento.Parser

  @type t :: Parser.t() | struct()
  @type opts :: [as: map() | list() | struct()]
  @type decode_err :: Parser.parse_err()

  @doc """
  Decode a bencoded value.
  """
  @spec decode(iodata(), opts()) :: {:ok, t()} | {:error, decode_err()}
  def decode(value, opts \\ []) do
    with {:ok, p} <- Parser.parse(value), do: {:ok, transform(p, opts)}
  end

  @doc """
  Decode a bencoded value, but raise an error if it fails.
  """
  @spec decode!(iodata(), opts()) :: t() | no_return()
  def decode!(value, opts \\ []) do
    value |> Parser.parse!() |> transform(opts)
  end

  @doc """
  Transform a parsed value into a struct.

      defmodule User do
        defstruct name: "John", age: 27
      end

      Bento.Decoder.transform(%{"name" => "Bob"}, as: %User{})
      # %User{name: "Bob", age: 27}
  """
  @spec transform(Parser.t(), opts()) :: t()
  def transform(value, as: as) when is_map(value) do
    transform_map(value, as)
  end

  def transform(value, as: as) when is_list(value) do
    transform_list(value, as)
  end

  def transform(value, as: as) when is_integer(value) do
    transform_time(value, as)
  end

  def transform(value, _opts), do: value

  # Transwform for maps and structs
  defp transform_map(value, as) when is_struct(as) do
    value
    |> transform_map(Map.from_struct(as))
    |> Map.put(:__struct__, as.__struct__)
  end

  defp transform_map(value, as) when is_map(as) do
    Enum.reduce(as, %{}, fn {key, default}, acc ->
      item = Map.get(value, to_string(key), default)

      Map.put(acc, key, transform(item, as: default))
    end)
  end

  defp transform_map(value, _as), do: value

  # Transform for lists
  defp transform_list(value, [to]) do
    Enum.map(value, &transform(&1, as: to))
  end

  defp transform_list(value, _as), do: value

  # Transform for DateTime
  defguardp is_time(value) when is_struct(value, DateTime)

  defp transform_time(value, as) when is_time(as) do
    case DateTime.from_unix(value) do
      {:ok, datetime} -> datetime
      _ -> value
    end
  end

  defp transform_time(value, _as), do: value
end
