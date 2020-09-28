class ActivityUI { // eslint-disable-line no-unused-vars
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
    return this.$activity.data('start-endpoint');
  }

  get stopEndpoint() {
    return this.$activity.data('stop-endpoint');
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
    this.$startButton.removeClass("hide");
    this.$pauseButton.addClass("hide");
    this.$stopButton.addClass("hide");
  }

  showPauseStop() {
    this.$startButton.addClass("hide");
    this.$pauseButton.removeClass("hide");
    this.$stopButton.removeClass("hide");
  }

  showPlayStop() {
    this.$startButton.removeClass("hide");
    this.$pauseButton.addClass("hide");
    this.$stopButton.removeClass("hide");
  }

  showError(error) {
    this.$activity.find(".callout.alert").html(error).removeClass("hide");
    this.showStart(this.$activity);
  }

  clockifySeconds(total_seconds) {
    const hours = Math.floor(total_seconds / (60 * 60))
    const minutes = Math.floor((total_seconds / 60) % 60)
    const seconds = total_seconds % 60

    return `${ hours }h ${ minutes }m ${ seconds }s`
  }

  updateElapsedTime() {
    const diff = this.now - this.initTime
    if(this.remaining <= diff) {
      this.stopCounter()
      return this.onStop();
    }
    this.$elapsed.html(this.clockifySeconds(this.elapsed + diff))
  }

  startCounter(data) {
    console.log("starting counter", data)
    clearInterval(this.interval);
    this.initTime = this.now;
    this.interval = setInterval(() => {
      this.updateElapsedTime();
      }, 1000);
  }

  stopCounter(data) {
    const diff = this.now - this.initTime
    console.log("stopping counter", data)
    this.elapsed = this.elapsed + diff;
    this.remaining = this.remaining - diff;
    clearInterval(this.interval);
  }
  
  showMilestone() {
    console.log("TODO: show milestone")
  }
}

