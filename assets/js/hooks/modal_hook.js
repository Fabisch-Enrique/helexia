

export default modal_hook = {
  mounted() {
    const video = document.getElementById("helexia-video-player")

    // Wait for modal animation to finish (Apple-style feel)
    setTimeout(() => {
      if (video) {
        video.play().catch(() => {})
      }

      // optional: open sound hook (see below)
      window.dispatchEvent(new Event("video_modal_opened"))
    }, 280)
  }
}
