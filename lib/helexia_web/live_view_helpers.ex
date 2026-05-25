defmodule HelexiaWeb.LiveViewHelpers do
  def qr_code(url) do
    url
    |> QRCodeEx.encode()
    |> QRCodeEx.svg(
      color: "#03B6AD",
      shape: "circle",
      width: 300,
      background_color: "#FFFFFF"
    )
  end

  def abbreviate(name) when is_binary(name) do
    words = String.split(name, ~r/\s+/, trim: true)

    case words do
      [] ->
        ""

      _ ->
        last_index = length(words) - 1

        words
        |> Enum.with_index()
        |> Enum.reject(fn {word, idx} ->
          # drop if it's a middle word and starts with a lowercase letter (Unicode-aware)
          idx != 0 and idx != last_index and String.match?(word, ~r/^\p{Ll}/u)
        end)
        |> Enum.map(fn {word, _idx} -> String.first(word) end)
        |> Enum.join("")
        |> String.upcase()
    end
  end
end
