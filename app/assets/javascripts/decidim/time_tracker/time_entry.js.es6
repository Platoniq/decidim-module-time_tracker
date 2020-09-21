// Controlls time entries

class TimeEntry { // eslint-disable-line no-unused-vars

  constructor() {
    this.elapsed_time = 0;
  }
  
  set setTimeStart(time_start) {
    if (time_start !== null)
      this.time_start = new Date(time_start);
  }
  
  set setTimePause(time_pause) {
    if (time_pause !== null)
      this.time_pause = new Date(time_pause);
  }
  
  set setTimeResume(time_resume) {
    if (time_resume !== null)
      this.time_resume = new Date(time_resume);
  }
  
  set setElapsedTime(elapsed_time) {
    if (elapsed_time !== null)
      this.elapsed_time = elapsed_time ;
  }

  get getElapsedTime() {
    let now = new Date();
    let added_time = 0;
    if (!this.elapsed_time) {
      added_time =  new Date() - this.time_start
    }
    else if (this.time_resume) {
      added_time = now - this.time_resume;
    }
    return this.elapsed_time + added_time;
  }
  
  get getTimePause() {
    return this.time_pause;
  }

  get getTimeResume() {
    return this.time_resume;
  }
  
  start() {
    this.time_start = new Date();
  }
  
  pause() {
    this.time_pause = new Date();
    if (this.time_resume) {
      this.elapsed_time += this.time_pause - this.time_resume;
    } else {
      this.elapsed_time += this.time_pause - this.time_start;
    }
    this.time_resume = undefined;
  }
  
  resume() {
    this.time_resume = new Date();
    this.time_pause = undefined;

  }
  
  stop() {
    this.time_end = new Date()
    if (!this.elapsed_time) {
      this.elapsed_time = this.time_end - this.time_start;
    }
    else if (this.time_resume) {
      this.elapsed_time += this.time_end - this.time_resume;
    }
  }
}
