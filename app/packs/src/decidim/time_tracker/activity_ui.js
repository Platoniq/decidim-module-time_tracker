// The timer card of one activity: its clock, its buttons and its messages.
// It only reflects state; time_tracker.js decides when to start and stop.

export const formatClock = (totalSeconds) => {
  const seconds = Math.max(0, Math.floor(totalSeconds));
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const rest = seconds % 60;

  return `${hours}:${String(minutes).padStart(2, "0")}:${String(rest).padStart(2, "0")}`;
};

const now = () => Math.floor(Date.now() / 1000);

export default class ActivityUI {
  constructor(element) {
    this.element = element;
    this.clock = element.querySelector("[data-timer-clock]");
    this.startButton = element.querySelector(".time-tracker-activity-start");
    this.pauseButton = element.querySelector(".time-tracker-activity-pause");
    this.stopButton = element.querySelector(".time-tracker-activity-stop");
    this.alert = element.querySelector(".callout.alert");
    this.notice = element.querySelector(".callout.success");
    this.milestone = element.querySelector(".milestone");
    this.interval = null;
    this.startedAt = null;
    this.onLimitReached = () => {};
  }

  get startEndpoint() {
    return this.element.dataset.startEndpoint;
  }

  get stopEndpoint() {
    return this.element.dataset.stopEndpoint;
  }

  // Seconds tracked before the current run started.
  get elapsed() {
    return parseInt(this.element.dataset.elapsedTime || 0, 10);
  }

  set elapsed(seconds) {
    this.element.dataset.elapsedTime = seconds;
  }

  // Seconds still allowed today.
  get remaining() {
    return parseInt(this.element.dataset.remainingTime || 0, 10);
  }

  set remaining(seconds) {
    this.element.dataset.remainingTime = Math.max(0, seconds);
  }

  isRunning() {
    return this.interval !== null;
  }

  // Shown and hidden with the hidden attribute, which reads the same to
  // assistive technology as it looks on screen.
  toggle(element, visible) {
    if (element) {
      element.hidden = !visible;
    }
  }

  showRunning() {
    this.toggle(this.startButton, false);
    this.toggle(this.pauseButton, true);
    this.toggle(this.stopButton, true);
    this.element.classList.add("is-running");
  }

  showIdle() {
    this.toggle(this.startButton, true);
    this.toggle(this.pauseButton, false);
    this.toggle(this.stopButton, false);
    this.element.classList.remove("is-running");
  }

  setBusy(busy) {
    [this.startButton, this.pauseButton, this.stopButton].forEach((button) => {
      if (button) {
        button.disabled = busy;
      }
    });
  }

  showError(message) {
    this.hideMessages();
    if (this.alert) {
      this.alert.textContent = message;
      this.toggle(this.alert, true);
    }
  }

  showNotice(message) {
    this.hideMessages();
    if (this.notice && message) {
      this.notice.textContent = message;
      this.toggle(this.notice, true);
    }
  }

  hideMessages() {
    this.toggle(this.alert, false);
    this.toggle(this.notice, false);
  }

  showMilestone() {
    this.toggle(this.milestone, true);
    this.milestone?.querySelector("input[type=text]")?.focus();
  }

  hideMilestone() {
    this.toggle(this.milestone, false);
  }

  render(seconds) {
    if (this.clock) {
      this.clock.textContent = formatClock(seconds);
    }
  }

  // Starts ticking. `alreadyElapsed` is how long the current run has been
  // going, for a counter that was running when the page loaded.
  startCounter(alreadyElapsed = 0) {
    clearInterval(this.interval);
    this.startedAt = now() - alreadyElapsed;
    this.showRunning();
    this.tick();
    this.interval = setInterval(() => this.tick(), 1000);
  }

  tick() {
    const run = now() - this.startedAt;
    if (run >= this.remaining) {
      this.stopCounter();
      this.onLimitReached();
      return;
    }
    this.render(this.elapsed + run);
  }

  stopCounter() {
    if (!this.isRunning()) {
      return;
    }
    const run = now() - this.startedAt;
    clearInterval(this.interval);
    this.interval = null;
    this.elapsed += run;
    this.remaining -= run;
    this.render(this.elapsed);
    this.showIdle();
  }
}
