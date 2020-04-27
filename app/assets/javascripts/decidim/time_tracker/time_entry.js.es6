// Controlls time entries

class TimeEntry {

  constructor() {
    this.elapsed_time = 0;
  }
  
  set setTimeStart(start_time) {
    this.start_time = start_time;
  }
  
  set setTimePause(pause_time) {
    this.pause_time = pause_time;
  }
  
  set setTimeResume(resume_time) {
    this.resume_time = resume_time;
  }
  
  set setElapsedTime(elapsed_time) {
    this.elapsed_time = elapsed_time;
  }

  get getElapsedTime() {
    let now = new Date();
    let added_time = 0;
    if (this.resume_time) {
      added_time = now - this.resume_time;
    }
    return this.elapsed_time + added_time;
  }
  
  start() {
    this.start_time = new Date();
  }
  
  pause() {
    this.pause_time = new Date();
    if (this.resume_time) {
      this.elapsed_time += this.pause_time - this.resume_time;
    } else {
      this.elapsed_time += this.pause_time - this.start_time;
    }
  }
  
  resume() {
    this.resume_time = new Date()
  }
  
  stop() {
    this.pause_time = new Date()
  }
}
