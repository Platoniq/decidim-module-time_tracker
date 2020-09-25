class ActivityUI { // eslint-disable-line no-unused-vars
  constructor(target) {
    this.$activity = $(target);
    this.$elapsed = this.$activity.find(".elapsed-time-clock");
    this.interval = null;
    this.initTime = this.now;
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
    return parseInt(this.$activity.data("elapsed-time"), 10);
  }

  set elapsed(seconds) {
    this.$activity.data("elapsed-time", seconds); 
  }

  showStart() {
    this.$activity.find(".time-tracker-activity-start").removeClass("hide");
    this.$activity.find(".time-tracker-activity-pause").addClass("hide");
    this.$activity.find(".time-tracker-activity-stop").addClass("hide");
  }

  showPauseStop() {
    this.$activity.find(".time-tracker-activity-start").addClass("hide");
    this.$activity.find(".time-tracker-activity-pause").removeClass("hide");
    this.$activity.find(".time-tracker-activity-stop").removeClass("hide");
  }

  showPlayStop() {
    this.$activity.find(".time-tracker-activity-start").removeClass("hide");
    this.$activity.find(".time-tracker-activity-pause").addClass("hide");
    this.$activity.find(".time-tracker-activity-stop").removeClass("hide");
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
    console.log(this.now, this.initTime, this)
    this.$elapsed.html(this.clockifySeconds(this.elapsed + this.now - this.initTime))
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
    console.log("stopping counter", data)
    this.elapsed = this.elapsed + this.now - this.initTime;
    clearInterval(this.interval);
  }
  
  showMilestone() {
    console.log("TODO: show milestone")
  }
}

