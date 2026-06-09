defmodule Helexia.Cldr do
  use Cldr,
    locales: [:en],
    providers: [Cldr.Number]
end
