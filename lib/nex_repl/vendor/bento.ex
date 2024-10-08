defmodule NexREPL.Vendor.Bento do
  @moduledoc """
  An incredibly fast, correct, pure-Elixir Bencoding library.

  This module contains high-level methods to encode and decode Bencoded data.
  """

  alias NexREPL.Vendor.Bento
  alias NexREPL.Vendor.Bento.{Encoder, Decoder}

  @doc """
  Bencode a value.

      iex> Bento.encode([1, "two", [3]])
      {:ok, "li1e3:twoli3eee"}

  """
  @spec encode(Encoder.bencodable(), Keyword.t()) :: success | failure
        when success: {:ok, Encoder.t() | String.t()},
             failure: {:error, Encoder.encode_err()}
  def encode(value, options \\ []) do
    {:ok, encode!(value, options)}
  rescue
    exception in [Bento.EncodeError] ->
      {:error, {:invalid, exception.value}}
  end

  @doc """
  Bencode a value, raising an exception on error.

      iex> Bento.encode!([1, "two", [3]])
      "li1e3:twoli3eee"
  """
  @spec encode!(Encoder.bencodable(), Keyword.t()) :: success | no_return()
        when success: Encoder.t() | String.t()
  def encode!(value, options \\ [])

  def encode!(value, iodata: true), do: Encoder.encode(value)

  def encode!(value, _) do
    encode!(value, iodata: true) |> IO.iodata_to_binary()
  end

  @doc """
  Bencode a value as iodata.

      iex> Bento.encode_to_iodata([1, "two", [3]])
      {:ok, [108, [[105, "1", 101], ["3", 58, "two"], [108, [[105, "3", 101]], 101]], 101]}
  """
  @spec encode_to_iodata(Encoder.bencodable(), Keyword.t()) :: success | failure
        when success: {:ok, iodata()},
             failure: {:error, Encoder.encode_err()}
  def encode_to_iodata(value, options \\ []) do
    encode(value, Keyword.merge(options, iodata: true))
  end

  @doc """
  Bencode a value as iodata, raises an exception on error.

      iex> Bento.encode_to_iodata!([1, "two", [3]])
      [108, [[105, "1", 101], ["3", 58, "two"], [108, [[105, "3", 101]], 101]], 101]
  """
  @spec encode_to_iodata!(Encoder.bencodable(), Keyword.t()) :: iodata() | no_return()
  def encode_to_iodata!(value, options \\ []) do
    encode!(value, Keyword.merge(options, iodata: true))
  end

  @doc """
  Decode bencoded data to a value.

      iex> Bento.decode("li1e3:twoli3eee")
      {:ok, [1, "two", [3]]}

  Use `:as` as option to transform the parsed value into a struct.

      defmodule User do
        defstruct name: "John", age: 27
      end

      Bento.decode("d4:name3:Bobe", as: %User{})
      # {:ok, %User{name: "Bob", age: 27}}
  """
  @spec decode(iodata(), Decoder.opts()) :: {:ok, Decoder.t()} | failure
        when failure: {:error, Decoder.decode_err()}
  def decode(iodata, options \\ []), do: Decoder.decode(iodata, options)

  @doc """
  Decode bencoded data to a value, raising an exception on error.

      iex> Bento.decode!("li1e3:twoli3eee")
      [1, "two", [3]]

  Use `:as` as option to transform the parsed value into a struct.

      defmodule User do
        defstruct name: "John", age: 27
      end

      Bento.decode!("d4:name3:Bobe", as: %User{})
      # %User{name: "Bob", age: 27}
  """
  @spec decode!(iodata(), Decoder.opts()) :: Decoder.t() | no_return()
  def decode!(iodata, options \\ []), do: Decoder.decode!(iodata, options)

end
