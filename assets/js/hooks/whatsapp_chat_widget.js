
const STORAGE_KEY = "website_whatsapp_chat_v1"

export default whatsapp_chat_widget = {
  mounted() {
    this.window = this.el.querySelector("[data-chat-window]")
    this.launcher = this.el.querySelector("[data-chat-launcher]")
    this.closeButton = this.el.querySelector("[data-close-chat]")

    this.openIcon = this.el.querySelector("[data-open-icon]")
    this.closeIcon = this.el.querySelector("[data-close-icon]")
    this.badge = this.el.querySelector("[data-unread-badge]")

    this.startPanel = this.el.querySelector("[data-start-panel]")
    this.startForm = this.el.querySelector("[data-start-form]")

    this.conversationPanel =
      this.el.querySelector("[data-conversation-panel]")

    this.messageList =
      this.el.querySelector("[data-message-list]")

    this.messageForm =
      this.el.querySelector("[data-message-form]")

    this.messageInput =
      this.el.querySelector("[data-message-input]")

    this.sendButton =
      this.el.querySelector("[data-send-button]")

    this.characterCount =
      this.el.querySelector("[data-character-count]")

    this.errorBanner =
      this.el.querySelector("[data-error-banner]")

    this.connectionStatus =
      this.el.querySelector("[data-connection-status]")

    this.state = {
      open: false,
      unread: 0,
      messages: new Map(),
      conversationId: null,
      visitorToken: null,
      socket: null,
      channel: null
    }

    this.restoreSession()
    this.bindEvents()

    if (
      this.state.conversationId &&
      this.state.visitorToken
    ) {
      this.showConversationPanel()
      this.loadConversation()
      this.connectSocket()
    }
  },

  destroyed() {
    this.disconnectSocket()
  },

  bindEvents() {
    this.launcher.addEventListener("click", () => {
      this.toggle()
    })

    this.closeButton.addEventListener("click", () => {
      this.close()
    })

    this.startForm.addEventListener(
      "submit",
      event => {
        event.preventDefault()
        this.startConversation()
      }
    )

    this.messageForm.addEventListener(
      "submit",
      event => {
        event.preventDefault()
        this.sendMessage()
      }
    )

    this.messageInput.addEventListener(
      "input",
      () => {
        this.updateCharacterCount()
        this.resizeTextarea()
      }
    )

    this.messageInput.addEventListener(
      "keydown",
      event => {
        if (
          event.key === "Enter" &&
          !event.shiftKey
        ) {
          event.preventDefault()
          this.sendMessage()
        }
      }
    )
  },

  toggle() {
    this.state.open
      ? this.close()
      : this.open()
  },

  open() {
    this.state.open = true
    this.state.unread = 0

    this.window.classList.remove(
      "pointer-events-none",
      "invisible",
      "translate-y-4",
      "scale-[0.98]",
      "opacity-0"
    )

    this.window.classList.add(
      "translate-y-0",
      "scale-100",
      "opacity-100"
    )

    this.window.setAttribute(
      "aria-hidden",
      "false"
    )

    this.launcher.setAttribute(
      "aria-expanded",
      "true"
    )

    this.openIcon.classList.add("hidden")
    this.closeIcon.classList.remove("hidden")

    this.updateUnreadBadge()

    window.setTimeout(() => {
      if (this.state.conversationId) {
        this.messageInput?.focus()
        this.scrollToBottom()
      } else {
        this.startForm
          .querySelector("input")
          ?.focus()
      }
    }, 100)
  },

  close() {
    this.state.open = false

    this.window.classList.add(
      "pointer-events-none",
      "invisible",
      "translate-y-4",
      "scale-[0.98]",
      "opacity-0"
    )

    this.window.classList.remove(
      "translate-y-0",
      "scale-100",
      "opacity-100"
    )

    this.window.setAttribute(
      "aria-hidden",
      "true"
    )

    this.launcher.setAttribute(
      "aria-expanded",
      "false"
    )

    this.openIcon.classList.remove("hidden")
    this.closeIcon.classList.add("hidden")
  },

  async startConversation() {
    this.clearError()

    const submitButton =
      this.startForm.querySelector(
        "button[type='submit']"
      )

    submitButton.disabled = true

    const formData =
      new FormData(this.startForm)

    try {
      const response = await fetch(
        this.el.dataset.createConversationUrl,
        {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "content-type": "application/json",
            "x-csrf-token": this.csrfToken()
          },
          body: JSON.stringify({
            name: formData.get("name"),
            email: formData.get("email")
          })
        }
      )

      const payload = await response.json()

      if (!response.ok) {
        throw new Error(
          payload.error ||
          "Unable to start the chat."
        )
      }

      this.state.conversationId =
        payload.data.conversation_id

      this.state.visitorToken =
        payload.data.visitor_token

      this.persistSession()
      this.showConversationPanel()
      this.connectSocket()
      this.messageInput.focus()
    } catch (error) {
      this.showError(error.message)
    } finally {
      submitButton.disabled = false
    }
  },

  async loadConversation() {
    try {
      const response = await fetch(
        `${this.el.dataset.conversationBaseUrl}/${this.state.conversationId}`,
        {
          headers: {
            authorization:
              `Bearer ${this.state.visitorToken}`
          }
        }
      )

      if (response.status === 404) {
        this.clearStoredSession()
        this.showStartPanel()
        return
      }

      const payload = await response.json()

      if (!response.ok) {
        throw new Error(
          payload.error ||
          "Unable to load conversation."
        )
      }

      this.state.messages.clear()

      for (const message of payload.data.messages) {
        this.upsertMessage(message, false)
      }

      this.renderMessages()
      this.scrollToBottom()
    } catch (error) {
      this.showError(error.message)
    }
  },

  async sendMessage() {
    const body =
      this.messageInput.value.trim()

    if (!body || body.length > 2000) {
      return
    }

    const clientMessageId =
      crypto.randomUUID()

    const optimistic = {
      id: `local-${clientMessageId}`,
      client_message_id: clientMessageId,
      body,
      sender_type: "visitor",
      status: "pending",
      inserted_at: new Date().toISOString()
    }

    this.upsertMessage(optimistic, true)

    this.messageInput.value = ""
    this.updateCharacterCount()
    this.resizeTextarea()
    this.sendButton.disabled = true

    try {
      const response = await fetch(
        this.el.dataset.sendMessageUrl,
        {
          method: "POST",
          credentials: "same-origin",
          headers: {
            "content-type": "application/json",
            "x-csrf-token": this.csrfToken(),
            authorization:
              `Bearer ${this.state.visitorToken}`
          },
          body: JSON.stringify({
            conversation_id:
              this.state.conversationId,
            client_message_id:
              clientMessageId,
            body
          })
        }
      )

      const payload = await response.json()

      if (!response.ok) {
        throw new Error(
          payload.error ||
          "Message could not be sent."
        )
      }

      this.removeLocalMessage(
        clientMessageId
      )

      this.upsertMessage(
        payload.data,
        true
      )
    } catch (error) {
      optimistic.status = "failed"

      this.state.messages.set(
        optimistic.id,
        optimistic
      )

      this.renderMessages()
      this.showError(error.message)
    } finally {
      this.sendButton.disabled = false
      this.messageInput.focus()
    }
  },

  connectSocket() {
    this.disconnectSocket()

    const socket = new Socket(
      "/socket",
      {
        params: {
          conversation_id:
            this.state.conversationId,
          visitor_token:
            this.state.visitorToken
        }
      }
    )

    socket.onOpen(() => {
      this.connectionStatus.textContent =
        "Connected to WhatsApp support"
    })

    socket.onError(() => {
      this.connectionStatus.textContent =
        "Connection interrupted"
    })

    socket.onClose(() => {
      this.connectionStatus.textContent =
        "Reconnecting…"
    })

    socket.connect()

    const channel = socket.channel(
      `website_chat:${this.state.conversationId}`,
      {}
    )

    channel
      .join()
      .receive("ok", () => {
        this.connectionStatus.textContent =
          "Connected to WhatsApp support"
      })
      .receive("error", () => {
        this.connectionStatus.textContent =
          "Unable to connect"
      })

    channel.on(
      "message_updated",
      message => {
        this.removeLocalMessage(
          message.client_message_id
        )

        const isIncoming =
          message.sender_type === "agent"

        this.upsertMessage(
          message,
          this.state.open
        )

        if (
          isIncoming &&
          !this.state.open
        ) {
          this.state.unread += 1
          this.updateUnreadBadge()
        }
      }
    )

    this.state.socket = socket
    this.state.channel = channel
  },

  disconnectSocket() {
    this.state.channel?.leave()
    this.state.socket?.disconnect()

    this.state.channel = null
    this.state.socket = null
  },

  upsertMessage(message, shouldScroll) {
    const key =
      message.id ||
      message.client_message_id

    this.state.messages.set(
      key,
      message
    )

    this.renderMessages()

    if (shouldScroll) {
      this.scrollToBottom()
    }
  },

  removeLocalMessage(clientMessageId) {
    if (!clientMessageId) return

    for (const [key, message] of this.state.messages) {
      if (
        message.client_message_id ===
        clientMessageId &&
        String(message.id).startsWith("local-")
      ) {
        this.state.messages.delete(key)
      }
    }
  },

  renderMessages() {
    const messages =
      [...this.state.messages.values()]
        .sort((a, b) => {
          return (
            new Date(a.inserted_at) -
            new Date(b.inserted_at)
          )
        })

    this.messageList.replaceChildren(
      ...messages.map(message =>
        this.messageElement(message)
      )
    )
  },

  messageElement(message) {
    const wrapper =
      document.createElement("div")

    const outgoing =
      message.sender_type === "visitor"

    wrapper.className = outgoing
      ? "flex justify-end"
      : "flex justify-start"

    const content =
      document.createElement("div")

    content.className =
      outgoing
        ? "max-w-[80%]"
        : "max-w-[82%]"

    const bubble =
      document.createElement("div")

    bubble.className = outgoing
      ? "rounded-[20px] rounded-br-md bg-gradient-to-br from-emerald-600 to-emerald-700 px-4 py-3 text-white shadow-lg shadow-emerald-600/15"
      : "rounded-[20px] rounded-bl-md border border-slate-200 bg-white px-4 py-3 text-slate-700 shadow-sm"

    const text =
      document.createElement("p")

    text.className =
      "whitespace-pre-wrap break-words text-[13px] leading-5"

    // textContent prevents message HTML injection.
    text.textContent = message.body

    bubble.appendChild(text)
    content.appendChild(bubble)

    const meta =
      document.createElement("div")

    meta.className = outgoing
      ? "mt-1.5 flex justify-end gap-2 px-1 text-[10px] text-slate-400"
      : "mt-1.5 flex gap-2 px-1 text-[10px] text-slate-400"

    const time =
      document.createElement("time")

    time.textContent =
      this.formatTime(message.inserted_at)

    const status =
      document.createElement("span")

    status.textContent =
      this.statusLabel(message.status)

    if (message.status === "failed") {
      status.className =
        "font-semibold text-rose-500"
    }

    meta.append(time, status)
    content.appendChild(meta)
    wrapper.appendChild(content)

    return wrapper
  },

  statusLabel(status) {
    switch (status) {
      case "pending":
        return "Sending…"
      case "sent":
        return "Sent"
      case "delivered":
        return "Delivered"
      case "read":
        return "Read"
      case "failed":
        return "Failed"
      default:
        return ""
    }
  },

  formatTime(value) {
    if (!value) return ""

    return new Intl.DateTimeFormat(
      undefined,
      {
        hour: "numeric",
        minute: "2-digit"
      }
    ).format(new Date(value))
  },

  showConversationPanel() {
    this.startPanel.classList.add("hidden")

    this.conversationPanel.classList.remove(
      "hidden"
    )

    this.conversationPanel.classList.add(
      "flex"
    )
  },

  showStartPanel() {
    this.startPanel.classList.remove("hidden")

    this.conversationPanel.classList.add(
      "hidden"
    )

    this.conversationPanel.classList.remove(
      "flex"
    )
  },

  updateCharacterCount() {
    const length =
      this.messageInput.value.length

    this.characterCount.textContent =
      `${length.toLocaleString()} / 2,000`

    this.sendButton.disabled =
      length === 0 || length > 2000
  },

  resizeTextarea() {
    this.messageInput.style.height = "auto"

    this.messageInput.style.height =
      `${Math.min(
        this.messageInput.scrollHeight,
        112
      )}px`
  },

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messageList.scrollTop =
        this.messageList.scrollHeight
    })
  },

  showError(message) {
    this.errorBanner.textContent = message
    this.errorBanner.classList.remove("hidden")
  },

  clearError() {
    this.errorBanner.textContent = ""
    this.errorBanner.classList.add("hidden")
  },

  updateUnreadBadge() {
    if (this.state.unread > 0) {
      this.badge.textContent =
        Math.min(this.state.unread, 99)

      this.badge.classList.remove("hidden")
      this.badge.classList.add("flex")
    } else {
      this.badge.classList.add("hidden")
      this.badge.classList.remove("flex")
    }
  },

  restoreSession() {
    try {
      const value =
        JSON.parse(
          localStorage.getItem(STORAGE_KEY)
        )

      if (
        value?.conversationId &&
        value?.visitorToken
      ) {
        this.state.conversationId =
          value.conversationId

        this.state.visitorToken =
          value.visitorToken
      }
    } catch (_error) {
      this.clearStoredSession()
    }
  },

  persistSession() {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        conversationId:
          this.state.conversationId,
        visitorToken:
          this.state.visitorToken
      })
    )
  },

  clearStoredSession() {
    localStorage.removeItem(STORAGE_KEY)

    this.state.conversationId = null
    this.state.visitorToken = null
  },

  csrfToken() {
    return document
      .querySelector(
        "meta[name='csrf-token']"
      )
      ?.getAttribute("content")
  }
}