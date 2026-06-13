export default about_us_page = {
    mounted() {
        this.abortController = new AbortController()

        const { signal } = this.abortController

        this.revealElements = [
            ...this.el.querySelectorAll("[data-reveal]")
        ]

        this.processLines = [
            ...this.el.querySelectorAll("[data-process-line]")
        ]

        this.interactiveCards = [
            ...this.el.querySelectorAll("[data-pointer-glow]")
        ]

        this.reducedMotion = window.matchMedia(
            "(prefers-reduced-motion: reduce)"
        ).matches

        if (this.reducedMotion) {
            this.showEverything()
            return
        }

        this.setupRevealObserver()
        this.setupPointerGlow(signal)
    },

    destroyed() {
        this.abortController?.abort()
        this.revealObserver?.disconnect()
    },

    showEverything() {
        this.revealElements.forEach((element) => {
            element.classList.add("is-visible")
        })

        this.processLines.forEach((line) => {
            line.classList.add("is-visible")
        })
    },

    setupRevealObserver() {
        this.revealObserver = new IntersectionObserver(
            (entries, observer) => {
                entries.forEach((entry) => {
                    if (!entry.isIntersecting) return

                    entry.target.classList.add("is-visible")
                    observer.unobserve(entry.target)
                })
            },
            {
                threshold: 0.14,
                rootMargin: "0px 0px -8% 0px"
            }
        )

        this.revealElements.forEach((element) => {
            this.revealObserver.observe(element)
        })

        this.processLines.forEach((line) => {
            this.revealObserver.observe(line)
        })
    },

    setupPointerGlow(signal) {
        this.interactiveCards.forEach((card) => {
            card.addEventListener(
                "pointermove",
                (event) => {
                    const rectangle = card.getBoundingClientRect()

                    const x = event.clientX - rectangle.left
                    const y = event.clientY - rectangle.top

                    card.style.setProperty("--pointer-x", `${x}px`)
                    card.style.setProperty("--pointer-y", `${y}px`)
                },
                { signal }
            )

            card.addEventListener(
                "pointerleave",
                () => {
                    card.style.setProperty("--pointer-x", "50%")
                    card.style.setProperty("--pointer-y", "50%")
                },
                { signal }
            )
        })
    }
}