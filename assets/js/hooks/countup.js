export default countup = {
  mounted() {
    const el = this.el;
    const endValue = el.dataset.countTo || el.dataset.toValue;
    const duration = el.dataset.duration || 1000;
    const suffix = el.dataset.suffix || "";

    let start = 0;
    const stepTime = Math.abs(Math.floor(duration / endValue));
    const timer = setInterval(() => {
      start += 1;
      el.innerText = start + suffix;
      if (start >= endValue) clearInterval(timer);
    }, stepTime);
  }

};