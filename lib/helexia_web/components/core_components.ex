defmodule HelexiaWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: HelexiaWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  attr :id, :string, default: "global-chat-widget"

  def chat_widget(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="whatsapp_chat_widget"
      data-create-conversation-url="/api/chat/conversations"
      data-conversation-base-url="/api/chat/conversations"
      data-send-message-url="/api/chat/messages"
      class="
        fixed
        bottom-[max(1rem,env(safe-area-inset-bottom))]
        right-[max(1rem,env(safe-area-inset-right))]
        z-[9999]
        flex flex-col items-end
        sm:bottom-6 sm:right-6
      "
    >
      <section
        data-chat-window
        role="dialog"
        aria-hidden="true"
        aria-label="WhatsApp support chat"
        class="
          sm:mb-4
          invisible
          opacity-0
          sm:static
          bg-white
          sm:h-[650px]
          sm:w-[390px]
          rounded-[28px]
          pointer-events-none
          flex-col overflow-hidden
          transition duration-300
          border border-slate-200
          sm:max-h-[calc(100vh-7rem)]
          fixed inset-x-3 bottom-24 top-3
          flex translate-y-4 scale-[0.98]
          shadow-[0_30px_90px_-25px_rgba(15,23,42,0.5)]
        "
      >
        <header class="relative overflow-hidden bg-slate-950 px-5 py-5 text-white">
          <div class="pointer-events-none absolute inset-0">
            <div class="absolute -right-12 -top-16 h-40 w-40 rounded-full bg-emerald-500/20 blur-3xl">
            </div>

            <div class="absolute -bottom-20 -left-10 h-40 w-40 rounded-full bg-blue-500/15 blur-3xl">
            </div>

            <div class="absolute inset-0 opacity-[0.07] [background-image:linear-gradient(rgba(255,255,255,.5)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.5)_1px,transparent_1px)] [background-size:24px_24px]">
            </div>
          </div>

          <div class="relative flex items-center justify-between gap-4">
            <div class="flex min-w-0 items-center gap-3">
              <div class="relative">
                <div class="flex h-12 w-12 items-center justify-center rounded-2xl border border-white/15 bg-white/10">
                  <.icon
                    name="hero-chat-bubble-left-right"
                    class="h-6 w-6 text-emerald-300"
                  />
                </div>

                <span class="absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full border-[3px] border-slate-950 bg-emerald-400">
                </span>
              </div>

              <div class="min-w-0">
                <div class="flex items-center gap-2">
                  <h2 class="truncate text-base font-bold">
                    WhatsApp Support
                  </h2>

                  <span class="rounded-full bg-emerald-400/10 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-emerald-300 ring-1 ring-emerald-300/20">
                    Online
                  </span>
                </div>

                <p class="mt-1 truncate text-xs text-slate-300">
                  Replies are delivered through WhatsApp
                </p>
              </div>
            </div>

            <button
              type="button"
              data-close-chat
              aria-label="Close chat"
              class="flex h-9 w-9 items-center justify-center rounded-xl text-slate-300 transition hover:bg-white/10 hover:text-white"
            >
              <.icon
                name="hero-x-mark"
                class="h-5 w-5"
              />
            </button>
          </div>

          <div class="relative mt-4 flex items-center gap-2 rounded-2xl border border-white/10 bg-white/[0.06] px-3 py-2">
            <span class="relative flex h-2 w-2">
              <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60">
              </span>

              <span class="relative inline-flex h-2 w-2 rounded-full bg-emerald-400"></span>
            </span>

            <span
              data-connection-status
              class="text-[11px] font-medium text-slate-300"
            >
              Secure website conversation
            </span>
          </div>
        </header>

        <div
          data-error-banner
          class="hidden border-b border-rose-200 bg-rose-50 px-4 py-3 text-xs font-medium text-rose-700"
        >
        </div>

        <div
          data-start-panel
          class="flex flex-1 flex-col justify-center bg-slate-50 px-5 py-6"
        >
          <div class="rounded-[24px] border border-slate-200 bg-white p-5 shadow-sm">
            <h3 class="text-lg font-bold text-slate-900">
              Start a conversation
            </h3>

            <p class="mt-2 text-sm leading-6 text-slate-500">
              Send us a message without leaving the website.
              Our reply will return here.
            </p>

            <form
              data-start-form
              class="mt-5 space-y-4"
            >
              <label class="block">
                <span class="mb-1.5 block text-xs font-semibold text-slate-700">
                  Name
                </span>

                <input
                  name="name"
                  maxlength="120"
                  autocomplete="name"
                  placeholder="Your name"
                  class="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm outline-none transition focus:border-emerald-500 focus:bg-white focus:ring-4 focus:ring-emerald-500/10"
                />
              </label>

              <label class="block">
                <span class="mb-1.5 block text-xs font-semibold text-slate-700">
                  Email
                </span>

                <input
                  name="email"
                  type="email"
                  autocomplete="email"
                  placeholder="you@example.com"
                  class="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm outline-none transition focus:border-emerald-500 focus:bg-white focus:ring-4 focus:ring-emerald-500/10"
                />
              </label>

              <button
                type="submit"
                class="flex h-12 w-full items-center justify-center gap-2 rounded-2xl bg-emerald-600 text-sm font-bold text-white shadow-lg shadow-emerald-600/20 transition hover:-translate-y-0.5 hover:bg-emerald-700 disabled:cursor-wait disabled:opacity-60"
              >
                <.icon
                  name="hero-chat-bubble-left-right"
                  class="h-5 w-5"
                /> Start chat
              </button>
            </form>
          </div>
        </div>

        <div
          data-conversation-panel
          class="hidden min-h-0 flex-1 flex-col"
        >
          <div
            data-message-list
            role="log"
            aria-live="polite"
            class="flex-1 space-y-5 overflow-y-auto bg-slate-50/80 px-4 py-5"
          >
          </div>

          <div
            data-new-message-notice
            class="mx-auto mb-2 hidden rounded-full bg-slate-950 px-3 py-1.5 text-[11px] font-semibold text-white shadow-lg"
          >
            New message
          </div>

          <footer class="border-t border-slate-200 bg-white p-4">
            <form
              data-message-form
              class="flex items-end gap-2"
            >
              <div class="flex min-h-12 flex-1 items-end rounded-[20px] border border-slate-200 bg-slate-50 px-3 py-2 transition focus-within:border-emerald-400 focus-within:bg-white focus-within:ring-4 focus-within:ring-emerald-500/10">
                <textarea
                  data-message-input
                  name="body"
                  rows="1"
                  maxlength="2000"
                  placeholder="Write a message..."
                  aria-label="Message"
                  class="max-h-28 min-h-7 flex-1 resize-none border-0 bg-transparent px-1 py-1 text-[13px] leading-5 text-slate-800 outline-none placeholder:text-slate-400 focus:ring-0"
                ></textarea>
              </div>

              <button
                data-send-button
                type="submit"
                aria-label="Send message"
                class="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-emerald-600 text-white shadow-lg shadow-emerald-600/20 transition hover:-translate-y-0.5 hover:bg-emerald-700 disabled:cursor-not-allowed disabled:bg-slate-300 disabled:shadow-none"
              >
                <.icon
                  name="hero-paper-airplane"
                  class="h-5 w-5"
                />
              </button>
            </form>

            <div class="mt-2 flex justify-between px-1">
              <p class="text-[9px] text-slate-400">
                Enter to send · Shift + Enter for a new line
              </p>

              <span
                data-character-count
                class="text-[9px] text-slate-400"
              >
                0 / 2,000
              </span>
            </div>
          </footer>
        </div>
      </section>

      <button
        data-chat-launcher
        type="button"
        aria-label="Open support chat"
        aria-expanded="false"
        class="
          group relative
          flex h-16 w-16
          items-center justify-center
          rounded-[22px]
          bg-emerald-600
          text-white
          shadow-[0_22px_50px_-14px_rgba(5,150,105,0.75)]
          transition duration-300
          hover:-translate-y-1
          hover:rotate-2
          hover:bg-emerald-700
          focus:outline-none
          focus:ring-4
          focus:ring-emerald-500/25
        "
      >
        <span data-open-icon>
          <.icon
            name="hero-chat-bubble-left-right"
            class="h-7 w-7"
          />
        </span>

        <span
          data-close-icon
          class="hidden"
        >
          <.icon
            name="hero-x-mark"
            class="h-7 w-7"
          />
        </span>

        <span
          data-unread-badge
          class="absolute -right-1 -top-1 hidden h-6 min-w-6 items-center justify-center rounded-full border-[3px] border-white bg-rose-500 px-1 text-[10px] font-bold text-white"
        >
          0
        </span>

        <span class="pointer-events-none absolute right-[76px] whitespace-nowrap rounded-xl bg-slate-950 px-3 py-2 text-xs font-semibold text-white opacity-0 shadow-xl transition group-hover:opacity-100">
          Chat with us
        </span>
      </button>
    </div>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(HelexiaWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(HelexiaWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
