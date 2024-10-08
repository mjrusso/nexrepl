defmodule NexREPL.Vendor.Bento.EncodeError do
  @moduledoc """
  Raised when a map with non-string keys is passed to the encoder.
  """

  defexception value: nil, message: nil

  def message(%{value: value, message: nil}) do
    "Unable to encode value: #{inspect(value)}"
  end

  def message(%{message: msg}), do: msg
end

defmodule NexREPL.Vendor.Bento.Encode do
  @moduledoc false

  alias NexREPL.Vendor.Bento

  defmacro __using__(_) do
    quote do
      # Macro to ensure a map key is a string or atom-as-a-string.
      defp encode_key(value) when is_binary(value), do: value
      defp encode_key(value) when is_atom(value), do: Atom.to_string(value)

      defp encode_key(value) do
        raise Bento.EncodeError,
          value: value,
          message: "Expected string or atom key, got: #{inspect(value)}"
      end
    end
  end
end

defprotocol NexREPL.Vendor.Bento.Encoder do
  @moduledoc """
  Protocol and implementations to encode Elixir data structures into
  their Bencoded forms.

  ## Examples

      iex> Bento.Encoder.encode("foo") |> IO.iodata_to_binary()
      "3:foo"

      iex> Bento.Encoder.encode([1, "two", [3]]) |> IO.iodata_to_binary()
      "li1e3:twoli4eee"

  ## Types what available or unavailable

  **Available types**: `Atom`, `BitString`, `Integer`, `List`, `Map`, `Range`,
  `Stream` and Struct (as a `Map`).

  **Unavailable types**: `Float`, `Function`, `PID`, `Port` and `Reference`.

  You can, and we recommend, [implement `Bento.Encoder` for a specific
  Struct](#module-implement-for-custom-structs) according to your needs.

  The Unavailable types will raise an `Bento.EncodeError` when you try to
  encode them. However, implementing `Bento.Encoder` for an unavailable
  type is also available, but it is not recommended.

  ## Implement for Custom Structs

  For the sake of security and logical integrity, we already implement
  the `Bento.Encoder` any types (but some not supported type will raise
  an error), and of course, including Struct.

  However, if you want to implement the `Bento.Encoder` for a specific
  Struct instead of using the default implementation (convert to `Map`
  by `Map.from_struct/1`), you can do it like this:

  ```elixir
  defimpl Bento.Encoder, for: MyStruct do
    def encode(struct) do
      # do something
    end
  end
  ```

  Here we have a specific example about a Struct that _"always be true"_:

  ```elixir
  defmodule Truly do
    defstruct be: true

    defimpl Bento.Encoder do
      def encode(_), do: "4:true"
    end
  end

  iex> %Truly{be: false} |> Bento.Encoder.encode() |> IO.iodata_to_binary()
  "4:true"
  ```
  """

  @fallback_to_any true

  @type bencodable :: atom() | Bento.Parser.t() | Enumerable.t()
  @type t :: iodata()
  @type encode_err :: {:invalid, term()}

  @doc """
  Encode an Elixir value into its Bencoded form.
  """
  @spec encode(bencodable()) :: t() | no_return()
  def encode(value)
end

defimpl NexREPL.Vendor.Bento.Encoder, for: Atom do
  alias NexREPL.Vendor.Bento

  def encode(nil), do: "4:null"
  def encode(true), do: "4:true"
  def encode(false), do: "5:false"

  def encode(atom) do
    atom |> Atom.to_string() |> Bento.Encoder.BitString.encode()
  end
end

defimpl NexREPL.Vendor.Bento.Encoder, for: BitString do
  def encode(str) do
    [str |> byte_size() |> Integer.to_string(), ?:, str]
  end
end

defimpl NexREPL.Vendor.Bento.Encoder, for: Integer do
  def encode(int) do
    [?i, Integer.to_string(int), ?e]
  end
end

defimpl NexREPL.Vendor.Bento.Encoder, for: Map do
  use NexREPL.Vendor.Bento.Encode

  alias NexREPL.Vendor.Bento
  alias NexREPL.Vendor.Bento.Encoder

  # `def encode(%{})` matchs all Maps, so we guard on map_size instead
  def encode(map) when map_size(map) == 0, do: "de"

  def encode(map) do
    fun = fn x ->
      [Encoder.BitString.encode(encode_key(x)), Encoder.encode(Map.get(map, x))]
    end

    [?d, map |> Map.keys() |> Enum.sort() |> Enum.map(fun), ?e]
  end
end

defimpl NexREPL.Vendor.Bento.Encoder, for: [List, Range, Stream] do
  alias NexREPL.Vendor.Bento.Encoder

  def encode([]), do: "le"

  def encode(coll) do
    [?l, coll |> Enum.map(&Encoder.encode/1), ?e]
  end
end

defimpl NexREPL.Vendor.Bento.Encoder, for: Any do

  alias NexREPL.Vendor.Bento

  # Default `encode/1` for ANY Struct.
  # If necessary, you can implement `Bento.Encoder` for a specific Struct.
  def encode(struct) when is_struct(struct) do
    struct |> Map.from_struct() |> Bento.Encoder.encode()
  end

  # Types that do not conform to the bencoding specification.
  # See: http://www.bittorrent.org/beps/bep_0003.html#bencoding
  def encode(value) do
    raise Bento.EncodeError,
      value: value,
      message: "Unsupported types: #{value_type(value)}"
  end

  defp value_type(value) when is_float(value), do: "Float"
  defp value_type(value) when is_function(value), do: "Function"
  defp value_type(value) when is_pid(value), do: "PID"
  defp value_type(value) when is_port(value), do: "Port"
  defp value_type(value) when is_reference(value), do: "Reference"
  defp value_type(value) when is_tuple(value), do: "Tuple"
end
