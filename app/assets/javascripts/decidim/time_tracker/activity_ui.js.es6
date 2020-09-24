class ActivityUI { // eslint-disable-line no-unused-vars
  constructor(target) {
    this.$activity = $(target).closest(".time-tracker-activity");
  }

  get startEndpoint() {
    return this.$activity.data('start-endpoint');
  }

  get stopEndpoint() {
    return this.$activity.data('stop-endpoint');
  }

  showStart() {
    this.$activity.find(".time-tracker-activity-start").removeClass("hide");
    this.$activity.find(".time-tracker-activity-pause").addClass("hide");
    this.$activity.find(".time-tracker-activity-stop").addClass("hide");
  };

  showPauseStop() {
    this.$activity.find(".time-tracker-activity-start").addClass("hide");
    this.$activity.find(".time-tracker-activity-pause").removeClass("hide");
    this.$activity.find(".time-tracker-activity-stop").removeClass("hide");
  };

  showPlayStop() {
    this.$activity.find(".time-tracker-activity-start").removeClass("hide");
    this.$activity.find(".time-tracker-activity-pause").addClass("hide");
    this.$activity.find(".time-tracker-activity-stop").removeClass("hide");
  };

  showError(error) {
    this.$activity.find(".callout.alert").html(error).removeClass("hide");
    this.showStart(this.$activity);
  };

  startCounter(time) {
    console.log("ok, TODO: start counter", time)
  }
  stopCounter(time) {
    console.log("ok, TODO: stop counter", time)
  }
}

