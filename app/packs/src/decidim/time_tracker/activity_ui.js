export default class ActivityUI { // eslint-disable-line no-unused-vars
  constructor(target) {
    this.activity = target;
    this.elapsedElement = this.activity.querySelector(".elapsed-time-clock");
    this.startButton = this.activity.querySelector(".time-tracker-activity-start");
    this.pauseButton = this.activity.querySelector(".time-tracker-activity-pause");
    this.stopButton = this.activity.querySelector(".time-tracker-activity-stop");
    this.interval = null;
    this.initTime = this.now;
    this.onStop = () => {};
  }

  get startEndpoint() {
    return this.activity.dataset.startEndpoint;
  }

  get stopEndpoint() {
    return this.activity.dataset.stopEndpoint;
  }

  get now() {
    return Math.floor(new Date().getTime() / 1000);
  }

  get elapsed() {
    return parseInt(this.activity.dataset.elapsedTime || 0, 10);
  }

  set elapsed(seconds) {
    this.activity.dataset.elapsedTime = seconds;
  }

  get remaining() {
    return parseInt(this.activity.dataset.remainingTime || 0, 10);
  }

  set remaining(seconds) {
    this.activity.dataset.remainingTime = seconds;
  }

  showStart() {
    if (this.startButton) {
      this.startButton.classList.remove("hidden");
    }
    if (this.pauseButton) {
      this.pauseButton.classList.add("hidden");
    }
    if (this.stopButton) {
      this.stopButton.classList.add("hidden");
    }
    return this;
  }

  showPauseStop() {
    if (this.startButton) {
      this.startButton.classList.add("hidden");
    }
    if (this.pauseButton) {
      this.pauseButton.classList.remove("hidden");
    }
    if (this.stopButton) {
      this.stopButton.classList.remove("hidden");
    }
    return this;
  }

  showPlayStop() {
    if (this.startButton) {
      this.startButton.classList.remove("hidden");
    }
    if (this.pauseButton) {
      this.pauseButton.classList.add("hidden");
    }
    if (this.stopButton) {
      this.stopButton.classList.add("hidden");
    }
    return this;
  }

  showError(error) {
    const calloutAlert = this.activity.querySelector(".callout.alert");
    if (calloutAlert) {
      calloutAlert.innerHTML = error;
      calloutAlert.classList.remove("hidden");
    }
    this.showStart();
    return this;
  }

  clockifySeconds(totalSeconds) {
    const hours = Math.floor(totalSeconds / (60 * 60))
    const minutes = Math.floor((totalSeconds / 60) % 60)
    const seconds = totalSeconds % 60

    return `${hours}h ${minutes}m ${seconds}s`
  }

  updateElapsedTime() {
    const diff = this.now - this.initTime;
    if (this.remaining <= diff) {
      this.stopCounter();
      return this.onStop();
    }
    this.elapsedElement.innerHTML = this.clockifySeconds(this.elapsed + diff);

    return null;
  }

  startCounter(data) {
    console.log("starting counter", data)
    clearInterval(this.interval);
    this.initTime = this.now;
    this.running = true;
    this.interval = setInterval(() => {
      this.updateElapsedTime();
    }, 1000);
    return this;
  }

  stopCounter(data) {
    const diff = this.now - this.initTime
    console.log("stopping counter", data)
    this.elapsed += diff;
    this.remaining -= diff;
    this.running = false;
    clearInterval(this.interval);
    return this;
  }

  isRunning() {
    return this.running;
  }

  showMilestone() {
    console.log("TODO: show milestone")
  }
}

