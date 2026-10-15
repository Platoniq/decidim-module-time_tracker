import TimerApi from "src/decidim/time_tracker/timer_api"
import ActivityUI from "src/decidim/time_tracker/activity_ui"

const POLL_EVERY = 8000;

// While a join request waits for an organiser, ask now and then whether it
// has been answered, and reload once it has so the timer (or the answer)
// shows up without the volunteer having to refresh.
const pollRequest = (statusUrl) => {
  if (!statusUrl) {
    return;
  }

  const interval = setInterval(() => {
    if (document.hidden) {
      return;
    }

    fetch(statusUrl, { headers: { Accept: "application/json" }, credentials: "same-origin" }).
      then((response) => response.json()).
      then((data) => {
        if (data.status && data.status !== "pending") {
          clearInterval(interval);
          window.location.reload();
        }
      }).
      catch(() => clearInterval(interval));
  }, POLL_EVERY);
};

// A short-lived confirmation floating over the page, so a long sentence
// never squeezes the activity row it came from.
const showNotice = (message) => {
  if (!message) {
    return;
  }

  const notice = document.createElement("div");
  notice.className = "time-tracker__notice";
  notice.setAttribute("role", "status");
  notice.textContent = message;
  document.body.appendChild(notice);

  setTimeout(() => notice.classList.add("is-leaving"), 7000);
  setTimeout(() => notice.remove(), 7600);
};

const setUpRequests = () => {
  document.querySelectorAll(".time-tracker-pending-request").forEach((element) => {
    pollRequest(element.dataset.statusUrl);
  });

  document.querySelectorAll("form.time-tracker-request-form").forEach((form) => {
    form.addEventListener("ajax:success", (event) => {
      const [data] = event.detail;
      const statusUrl = form.dataset.statusUrl;
      const action = form.closest(".time-tracker__action");

      if (data.html && action) {
        action.outerHTML = data.html;
      } else {
        const pending = document.createElement("span");
        pending.className = "time-tracker__state time-tracker__state--pending";
        pending.textContent = form.dataset.pendingLabel || "";
        form.replaceWith(pending);
      }
      showNotice(data.message);

      pollRequest(statusUrl);
    });

    form.addEventListener("ajax:error", (event) => {
      const [data] = event.detail;
      const error = document.createElement("span");
      error.className = "time-tracker__state time-tracker__state--rejected";
      error.setAttribute("role", "alert");
      error.textContent = (data && data.message) || form.dataset.errorMessage || "";
      form.replaceWith(error);
    });
  });
};

const setUpTimers = () => {
  const timers = [];

  document.querySelectorAll(".time-tracker-activity").forEach((element) => {
    const ui = new ActivityUI(element);
    const api = new TimerApi(ui.startEndpoint, ui.stopEndpoint);
    timers.push(ui);

    // The server also stops a counter that runs past the daily limit; this
    // keeps the page in step with it.
    ui.onLimitReached = () => {
      ui.showError(element.dataset.textCounterStopped);
      api.stop().catch(() => {});
    };

    if (element.dataset.counterActive === "true") {
      ui.startCounter();
    }

    ui.startButton?.addEventListener("click", () => {
      ui.setBusy(true);
      ui.hideMessages();
      ui.hideMilestone();
      api.start().
        then(() => {
          // Starting one activity stops whatever else was running, on the
          // server as well as here.
          timers.filter((other) => other !== ui && other.isRunning()).forEach((other) => other.stopCounter());
          ui.startCounter();
        }).
        catch((error) => ui.showError(error.message)).
        finally(() => ui.setBusy(false));
    });

    ui.pauseButton?.addEventListener("click", () => {
      ui.setBusy(true);
      api.stop().
        then(() => ui.stopCounter()).
        catch((error) => ui.showError(error.message)).
        finally(() => ui.setBusy(false));
    });

    ui.stopButton?.addEventListener("click", () => {
      ui.setBusy(true);
      api.stop().
        then(() => {
          ui.stopCounter();
          ui.showNotice(element.dataset.textSessionSaved);
          ui.showMilestone();
        }).
        catch((error) => ui.showError(error.message)).
        finally(() => ui.setBusy(false));
    });

    element.querySelector("[data-milestone-dismiss]")?.addEventListener("click", () => ui.hideMilestone());
  });
};

document.addEventListener("DOMContentLoaded", () => {
  setUpRequests();
  setUpTimers();
});
