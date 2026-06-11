defmodule Helexia.PayloadParser do
  def events(payload) when is_map(payload) do
    payload
    |> Map.get("entry", [])
    |> Enum.flat_map(&entry_events/1)
  end

  def events(_), do: []

  defp entry_events(entry) do
    entry
    |> Map.get("changes", [])
    |> Enum.flat_map(fn change ->
      value = Map.get(change, "value", %{})

      message_events(value) ++ status_events(value)
    end)
  end

  defp message_events(value) do
    value
    |> Map.get("messages", [])
    |> Enum.flat_map(fn message ->
      case parse_message(message) do
        nil -> []
        event -> [event]
      end
    end)
  end

  defp parse_message(
         %{
           "id" => id,
           "from" => from,
           "type" => "text",
           "text" => %{"body" => body}
         } = message
       ) do
    %{
      type: :incoming_text,
      provider_message_id: id,
      from: from,
      body: body,
      context_message_id: get_in(message, ["context", "id"]),
      raw_payload: message
    }
  end

  defp parse_message(_), do: nil

  defp status_events(value) do
    value
    |> Map.get("statuses", [])
    |> Enum.map(fn status ->
      %{
        type: :message_status,
        provider_message_id: Map.get(status, "id"),
        status: Map.get(status, "status"),
        raw_payload: status
      }
    end)
  end
end
