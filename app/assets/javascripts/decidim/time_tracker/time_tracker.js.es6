//= require decidim/time_tracker/timer_api
//= require decidim/time_tracker/activity_ui
//= require decidim/time_tracker/milestone
//= require jsrender.min
//= require_self

$(() => {

  $(".time-tracker-activity").each(function() {
    const $activity = $(this);
    const $milestone = $activity.find(".milestone");
    const activity = new ActivityUI($activity);
    const api = new TimerApi(activity.startEndpoint, activity.stopEndpoint);

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
        .done((data) => activity.startCounter(data))
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

      // let milestone = new Milestone(time_entry);
      // activities[id].milestone = milestone;
      // milestone.url = $button_stop.data('endpoint') + '/' + time_entry.id +  '/milestones'
      // let tmpl = $.templates("#milestone_form");
      // let html = tmpl.render(milestone);
      // let object = $("div[data-activity-id='" + id + "']").after(html);
      // let $form = object.next().find('form');
      // $form.find(':submit').click((event) => {
      //   event.preventDefault();

      //   $.ajax({
      //     type: "POST",
      //     url: milestone.url,
      //     processData: false,
      //     contentType: false,
      //     headers: {
      //       'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
      //     },
      //     data: new FormData($form[0]), // serializes the form's elements.
      //     success: () => {
      //       location.reload();
      //     },
      //     error: () => {
      //       location.reload()
      //     }
      //   });
      // })
});

