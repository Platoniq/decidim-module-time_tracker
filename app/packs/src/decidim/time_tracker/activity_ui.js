export default class ActivityUI { // eslint-disable-line no-unused-vars
  constructor(target) {
    this.$activity = $(target);
    this.$elapsed = this.$activity.find(".elapsed-time-clock");
    this.$startButton = this.$activity.find(".time-tracker-activity-start");
    this.$pauseButton = this.$activity.find(".time-tracker-activity-pause");
    this.$stopButton = this.$activity.find(".time-tracker-activity-stop");
    this.interval = null;
    this.initTime = this.now;
    this.onStop = $.noop;
  }

  get startEndpoint() {
    return this.$activity.data("start-endpoint");
  }

  get stopEndpoint() {
    return this.$activity.data("stop-endpoint");
  }

  get now() {
    return Math.floor(new Date().getTime() / 1000);
  }

  get elapsed() {
    return parseInt(this.$activity.data("elapsed-time") || 0, 10);
  }

  set elapsed(seconds) {
    this.$activity.data("elapsed-time", seconds); 
  }

  get remaining() {
    return parseInt(this.$activity.data("remaining-time") || 0, 10);
  }

  set remaining(seconds) {
    this.$activity.data("remaining-time", seconds); 
  }

  showStart() {
    this.$startButton.removeClass("hidden");
    this.$pauseButton.addClass("hidden");
    this.$stopButton.addClass("hidden");
    return this;
  }

  showPauseStop() {
    this.$startButton.addClass("hidden");
    this.$pauseButton.removeClass("hidden");
    this.$stopButton.removeClass("hidden");
    return this;
  }

  showPlayStop() {
    this.$startButton.removeClass("hidden");
    this.$pauseButton.addClass("hidden");
    this.$stopButton.removeClass("hidden");
    return this;
  }

  showError(error) {
    this.$activity.find(".callout.alert").html(error).removeClass("hidden");
    this.showStart(this.$activity);
    return this;
  }

  clockifySeconds(totalSeconds) {
    const hours = Math.floor(totalSeconds / (60 * 60))
    const minutes = Math.floor((totalSeconds / 60) % 60)
    const seconds = totalSeconds % 60

    return `${hours}h ${minutes}m ${seconds}s`
  }

  updateElapsedTime() {
    const diff = this.now - this.initTime
    if (this.remaining <= diff) {
      this.stopCounter()
      return this.onStop();
    }
    this.$elapsed.html(this.clockifySeconds(this.elapsed + diff));

    return null;
  }

  startCounter(data) {
    console.log("starting counter", data)
    clearInterval(this.interval);
    this.initTime = this.now;
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
    clearInterval(this.interval);
    return this;
  }

  isRunning() {
    return Boolean(this.interval);
  }

  showMilestone() {
    console.log("TODO: show milestone")
  }
}

