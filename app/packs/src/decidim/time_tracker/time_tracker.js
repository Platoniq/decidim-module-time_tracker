import TimerApi from "src/decidim/time_tracker/timer_api"
import ActivityUI from "src/decidim/time_tracker/activity_ui"
import updateReports from "src/decidim/time_tracker/updateReports"

document.addEventListener("DOMContentLoaded", () => {
  updateReports();
  // For each request track ajax responses
  const timeTrackerRequests = document.querySelectorAll(".time-tracker-request");
  
  timeTrackerRequests.forEach((element) => {
    element.addEventListener("ajax:success", (event) => {
      const detail = event.detail;
      const data = detail[0];

      const newElement = document.createElement("div");
      newElement.classList.add("callout", "success", "m-4");
      newElement.textContent = data.message;

      element.replaceWith(newElement);
    });
  });

  timeTrackerRequests.forEach((form) => {
    form.addEventListener("ajax:error", (event) => {
      const detail = event.detail;
      const data = detail[0];

      const callout = document.createElement("div");
      callout.classList.add("callout", "alert", "m-4");
      callout.textContent = data.message;

      form.parentNode.insertBefore(callout, form.nextSibling);
      form.style.display = "none";

      setTimeout(() => {
        callout.style.transition = "opacity 1s";
        callout.style.opacity = 0;

        callout.addEventListener("transitionend", () => {
          callout.remove();
          form.style.display = "block";
        });
      }, 2000);
    });
  });

  // For each activity set up the counters
  const activities = document.querySelectorAll(".time-tracker-activity");

  activities.forEach((activityElement) => {
    const milestone = activityElement.querySelector(".milestone");
    const activity = new ActivityUI(activityElement);
    const api = new TimerApi(activity.startEndpoint, activity.stopEndpoint);

    // store api
    activityElement._activity = activity;
    activityElement._api = api;

    if (activityElement.dataset.counterActive === "true") {
      activity.showPauseStop();
      activity.startCounter();
    }

    activity.onStop = () => {
      console.log("automatic stop");
      activity.showError(activityElement.dataset.textCounterStopped);
      activity.showStart();
      // Unnecessary if the job is working well
      api.stop();
    };

    const startButton = activityElement.querySelector(".time-tracker-activity-start");
    const pauseButton = activityElement.querySelector(".time-tracker-activity-pause");
    const stopButton = activityElement.querySelector(".time-tracker-activity-stop");

    // Start button click
    if (startButton) {
      startButton.addEventListener("click", () => {
        api.start().
          then((data) => {
            // select all counters except the clicked one
            activity.activity.classList.add("current")
            const otherActivities = document.querySelectorAll('div[class="time-tracker-activity"]');
            // stop all these counters
            otherActivities.forEach((otherActivityElement) => {
              const activityData = otherActivityElement._activity;
              if (activityData.isRunning()) {
                activityData.showPlayStop();
                activityData.stopCounter();
              }
            });
            // start only the clicked counter
            activity.showPauseStop();
            activity.startCounter(data);
            activity.activity.classList.remove("current")
          }).
          catch(activity.showError.bind(activity));
      });
    }

    if (pauseButton) {
      pauseButton.addEventListener("click", () => {
        activity.showPlayStop();
        api.stop().
          then((data) => activity.stopCounter(data)).
          catch(activity.showError.bind(activity));
      });
    }

    if (stopButton) {
      stopButton.addEventListener("click", () => {
        activity.showStart();
        api.stop().
          then((data) => {
            activity.stopCounter(data);
            console.log("show milestone creator");
            milestone.classList.remove("hidden");
          }).
          catch(activity.showError.bind(activity));
      });
    }
  });
});

