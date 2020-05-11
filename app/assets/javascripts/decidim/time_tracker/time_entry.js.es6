// Controlls time entries

class TimeEntry {

  constructor() {
    this.elapsed_time = 0;
  }
  
  set setTimeStart(time_start) {
    this.time_start = new Date(time_start);
  }
  
  set setTimePause(pause_time) {
    this.pause_time = new Date(pause_time);
  }
  
  set setTimeResume(resume_time) {
    this.resume_time = new Date(resume_time);
  }
  
  set setElapsedTime(elapsed_time) {
    this.elapsed_time = elapsed_time;
  }

  get getElapsedTime() {
    let now = new Date();
    let added_time = 0;
    if (!this.elapsed_time) {
      added_time =  new Date() - this.time_start
    }
    else if (this.resume_time) {
      added_time = now - this.resume_time;
    }
    return this.elapsed_time + added_time;
  }
  
  start() {
    this.time_start = new Date();
  }
  
  pause() {
    this.pause_time = new Date();
    if (this.resume_time) {
      this.elapsed_time += this.pause_time - this.resume_time;
    } else {
      this.elapsed_time += this.pause_time - this.time_start;
    }
  }
  
  resume() {
    this.resume_time = new Date()
  }
  
  stop() {
    this.time_end = new Date()
    if (this.resume_time) {
      this.elapsed_time += this.time_end - this.resume_time;
    } else {
      this.elapsed_time += this.time_end - this.time_start;
    }
  }
}
