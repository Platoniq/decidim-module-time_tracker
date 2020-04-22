// Controlls time entries

function TimeEntry(start_time, elapsed_time) {
  var self = this;
  self.elapsed_time = 0;
}

TimeEntry.prototype.setTimeStart = function(start_time) {
  this.start_time = start_time;
}

TimeEntry.prototype.setTimePause = function(pause_time) {
  this.pause_time = pause_time;
}

TimeEntry.prototype.setTimeResume = function(resume_time) {
  this.resume_time = resume_time;
}

TimeEntry.prototype.setElapsedTime = function(elapsed_time) {
  this.elapsed_time = elapsed_time;
}

TimeEntry.prototype.start = function(start_time) {
  this.start_time = new Date();
}

TimeEntry.prototype.pause = function() {
  this.pause_time = new Date();
  if (this.resume_time) {
    this.elapsed_time += this.pause_time - this.resume_time;
  } else {
    this.elapsed_time += this.pause_time - this.start_time;
  }
}

TimeEntry.prototype.resume = function() {
  this.resume_time = new Date()
}

TimeEntry.prototype.stop = function() {
  this.pause_time = new Date()
}