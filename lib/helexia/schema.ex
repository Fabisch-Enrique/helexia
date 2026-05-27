defmodule Helexia.Schema do
  @moduledoc """

  A module for shared schema functionality.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      use TypedEctoSchema
      use Waffle.Ecto.Schema
      use VCUtils.FieldQueries
      use VCUtils.RepoCrud, repo: Helexia.Repo

      import Ecto.Changeset
      import Ecto.Query, warn: false
      import Ecto.Multi, except: [inspect: 1, inspect: 2]

      @foreign_key_type :binary_id
      @timestamp_opts [type: :utc_datetime]
      @primary_key {:id, :binary_id, autogenerate: true}

      def custom_paginator(queryable, opts) do
        page = Keyword.get(opts, :page, 1)
        page_size = Keyword.get(opts, :page_size, 10)
        offset = (max(page, 1) - 1) * page_size

        queryable
        |> order_by([b], asc: b.inserted_at)
        |> limit(^page_size)
        |> offset(^offset)
        |> @repo.all()
        |> then(
          &%{
            entries: &1,
            metadata: %{page: page, page_size: page_size}
          }
        )
      end

      def cast_slug(%Ecto.Changeset{} = changeset, source_field, slug_field \\ :slug) do
        slug_override = get_field(changeset, slug_field)
        raw = get_field(changeset, source_field)

        slug =
          cond do
            not is_nil(slug_override) and slug_override != "" ->
              Slug.slugify(slug_override, separator: "_")

            not is_nil(raw) and raw != "" ->
              Slug.slugify(raw, separator: "_")

            true ->
              nil
          end

        put_change(changeset, slug_field, slug)
      end
    end
  end
end
