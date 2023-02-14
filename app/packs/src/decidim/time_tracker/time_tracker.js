import TimerApi from "src/decidim/time_tracker/timer_api"
import ActivityUI from "src/decidim/time_tracker/activity_ui"
import updateReports from "src/decidim/time_tracker/updateReports"

$(() => {
  $(document).ready(updateReports);
  // For each request track ajax responses
  $(document).on("ajax:success", ".time-tracker-request", (event) => {
    const detail = event.detail;
    const data = detail[0];
    $(event.target).replaceWith(`<div class="callout success">${data.message}</div>`);
  })
  $(document).on("ajax:error", ".time-tracker-request", (event) => {
    const detail = event.detail;
    const data = detail[0];
    const $form = $(event.target);
    const $callout = $(`<div class="callout alert">${data.message}</div>`).insertAfter($form);
    $form.hide();
    setTimeout(() => $callout.fadeOut(() => {$callout.remove(); $form.show();}), 2000);
  });
 
  // For each activty set up the counters
  $(".time-tracker-activity").each(function() {
    const $activity = $(this);
    const $milestone = $activity.find(".milestone");
    const activity = new ActivityUI($activity);
    const api = new TimerApi(activity.startEndpoint, activity.stopEndpoint);
    // store api
    $activity.data('_activity', activity);
    $activity.data('_api', api);
    if($activity.data("counter-active")) {
      activity.showPauseStop();
      activity.startCounter();
    }

    activity.onStop = () => {
      console.log("automatic stop");
      activity.showError($activity.data("text-counter-stopped"));
      activity.showStart();
      api.stop(); // Unnecessary if the job is working well
    };

    $activity.find(".time-tracker-activity-start").on("click", () => {
      activity.showPauseStop();
      api.start()
        .done((data) => {
          // stop others
          $(".time-tracker-activity").each(function() {
            const activity = $(this).data("_activity");
            if(activity.isRunning()) {
              activity.showPlayStop().stopCounter();
            }
          });
          activity.startCounter(data)
        })
        .fail(activity.showError.bind(activity));
    });


    $activity.find(".time-tracker-activity-pause").on("click", () => {
      activity.showPlayStop();
      api.stop()
        .done((data) => activity.stopCounter(data))
        .fail(activity.showError.bind(activity));
    });

    $activity.find(".time-tracker-activity-stop").on("click", () => {
      activity.showStart();
      api.stop()
        .done((data) => { 
          activity.stopCounter(data);
          console.log("show milestone creator");
          $milestone.removeClass("hide");
         })
        .fail(activity.showError.bind(activity));
    });
  });

});

