defmodule HelexiaWeb.LiveViewHelpers do
  @default_options [
    group: :auto,
    separator: :auto,
    format: :standard
  ]

  def generate_qr_code(url) do
    url
    |> QRCodeEx.encode()
    |> QRCodeEx.svg(
      color: "#03B6AD",
      shape: "circle",
      width: 300,
      background_color: "#022a65"
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

  def format_number(number, opts \\ @default_options)
  def format_number(nil, _opts), do: nil

  def format_number(number, opts) when is_list(opts) do
    num = if is_integer(number), do: number, else: number |> String.to_integer()
    num |> Cldr.Number.to_string!(Keyword.merge(@default_options, opts))
  end

  def pilot_status_badge_class(status) do
    case status do
      status when status in ["active", "live", "in progress", "ongoing"] ->
        "border-emerald-200 bg-emerald-50 text-emerald-700"

      status when status in ["completed", "complete", "delivered"] ->
        "border-sky-200 bg-sky-50 text-sky-700"

      status when status in ["planned", "upcoming", "preparation"] ->
        "border-amber-200 bg-amber-50 text-amber-700"

      status when status in ["paused", "on hold"] ->
        "border-orange-200 bg-orange-50 text-orange-700"

      _ ->
        "border-slate-200 bg-slate-50 text-slate-700"
    end
  end

  def pilot_status_dot_class(status) do
    case status do
      status when status in ["active", "live", "in progress", "ongoing"] ->
        "bg-emerald-500"

      status when status in ["completed", "complete", "delivered"] ->
        "bg-sky-500"

      status when status in ["planned", "upcoming", "preparation"] ->
        "bg-amber-500"

      status when status in ["paused", "on hold"] ->
        "bg-orange-500"

      _ ->
        "bg-slate-500"
    end
  end
end
