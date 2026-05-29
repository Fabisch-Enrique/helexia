export default clock = {
  mounted() {
    this.updateTime();
    this.timer = setInterval(() => {
      this.updateTime();
    }, 1000);
  },

  destroyed() {
    if (this.timer) {
      clearInterval(this.timer);
    }
  },

  updateTime() {
    const now = new Date();
    
    // Format time with seconds
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const seconds = now.getSeconds().toString().padStart(2, '0');
    
    // Create time string with highlighted seconds
    const timeString = `${hours}:${minutes}:<span class="seconds">${seconds}</span>`;
    
    // Format date
    const options = { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    };
    
    const dateString = now.toLocaleDateString('en-US', options);
    
    // Update DOM elements within this hook's element
    const timeElement = document.getElementById('current_time');
    const dateElement = document.getElementById('current_date');

    if (timeElement) {
      timeElement.innerHTML = timeString;
    }
    
    if (dateElement) {
      dateElement.textContent = dateString;
    }
  }
};