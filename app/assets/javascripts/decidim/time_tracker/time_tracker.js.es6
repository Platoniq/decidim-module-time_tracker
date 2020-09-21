//= require decidim/time_tracker/time_entry
//= require decidim/time_tracker/milestone
//= require jsrender.min
//= require_self

$(() => {
  const $activities = $('.activity');
  let activities = {};

   const updateElapsedTime = (id) => {
    var elapsed_time = activities[id].getElapsedTime
    var seconds = Math.floor(elapsed_time/ (1000));
    var minutes = Math.floor(seconds/ 60);
    var hour = Math.floor(minutes / 60);
    $("[data-activity-id='elapsed_time_" + id +"'").html( hour % 60 + "h " + minutes % 60 + "m " + seconds % 60 + "s");
  }

  $activities.each(function() {
    const id = $(this).data('activity-id');

    const last_time_entry = $("div[data-activity-id='elapsed_time_" + id + "'").data('time-entry');
    const timestamp = $("div[data-activity-id='elapsed_time_" + id + "'").data('elapsed-time'); 
    const $button_start = $(".time-tracker-activity-start[data-activity-id='" + id + "']");
    const $button_pause = $(".time-tracker-activity-pause[data-activity-id='" + id + "']");
    const $button_stop = $(".time-tracker-activity-stop[data-activity-id='" + id + "']");

    if (last_time_entry) {
      let time_entry = new TimeEntry();
      time_entry.id = last_time_entry.id;
      time_entry.setTimeStart = last_time_entry.time_start;
      time_entry.setElapsedTime = (timestamp)? parseInt(timestamp) : 0;
      time_entry.setTimePause = last_time_entry.time_pause;
      time_entry.setTimeResume = last_time_entry.time_resume;
      activities[id] = time_entry;

      updateElapsedTime(id);

      if (time_entry.time_pause === undefined) {
        activities[id].interval = setInterval(() => {
          updateElapsedTime(id)
        }, 100);
      }
    }

    // Handle click on start button
    $button_start.on("click", () => {
      let time_entry = activities[id];
      let elapsed_time;

      // hide play, show pause, show stop
      $button_start.addClass("hide");
      $button_pause.removeClass("hide");
      $button_stop.removeClass("hide");
      if (!time_entry) {
        time_entry = new TimeEntry();
        time_entry.start();
        activities[id] = time_entry;
        $.ajax({
          method: "POST",
          url: $button_start.data('endpoint'),
          contentType: "application/json",
          headers: {
            'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
          },
          data: JSON.stringify({ time_entry }),
          success: (data) => {
            time_entry.id = data.time_entry_id
          },
          error: (jq, textStatus) => {
            console.error("error starting time",textStatus);
          }
        });
      }  else if (!time_entry.interval) {
        time_entry.resume();
        $.ajax({
          method: "PATCH",
          url: $button_stop.data('endpoint') + '/' + time_entry.id,
          contentType: "application/json",
          headers: {
            'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
          },
          data: JSON.stringify({ time_entry }),
          error: (jq, textStatus) => {
            console.error("error resuming time", textStatus);
          }
        });
      }

      elapsed_time = time_entry.getElapsedTime;
      if (!time_entry.interval) {
        activities[id].interval = setInterval(() => {
          elapsed_time += 100;
          let seconds = Math.floor(elapsed_time/ (1000));
          let minutes = Math.floor(seconds/ 60);
          let hour = Math.floor(minutes / 60);
          $("[data-activity-id='elapsed_time_" + id +"'").html( hour % 60 + "h " + minutes % 60 + "m " + seconds % 60 + "s");
        }, 100);
      }
    });

    $button_pause.on("click", () => {
      let time_entry = activities[id];

      // show play, hide pause, show stop
      $button_start.removeClass("hide");
      $button_pause.addClass("hide");
      $button_stop.removeClass("hide");

      time_entry.pause();
      clearInterval(time_entry.interval);
      time_entry.interval = 0;
      $.ajax({
        method: "PATCH",
        url: $button_stop.data('endpoint') + '/' + time_entry.id,
        contentType: "application/json",
        headers: {
          'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
        },
        data: JSON.stringify({ time_entry }),
        error: (jq, textStatus) => {
          console.error("error pausing time", textStatus);
        }
      });
    });

    $button_stop.on("click", () => {
      let time_entry = activities[id];

      // show play, hide pause, hide stop
      $button_start.removeClass("hide");
      $button_pause.addClass("hide");
      $button_stop.addClass("hide");

      time_entry.stop();
      clearInterval(time_entry.interval);
      time_entry.interval = -1;
      $.ajax({
        method: "PATCH",
        url: $button_stop.data('endpoint') + '/' + time_entry.id,
        contentType: "application/json",
        headers: {
          'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
        },
        data: JSON.stringify({ time_entry }),
        error: (jq, textStatus) => {
          console.error("error stopping time", textStatus);
        }
      });

      if (!activities[id].milestone) {
        let milestone = new Milestone(time_entry);
        activities[id].milestone = milestone;
        milestone.url = $button_stop.data('endpoint') + '/' + time_entry.id +  '/milestones'
        let tmpl = $.templates("#milestone_form");
        let html = tmpl.render(milestone);
        let object = $("div[data-activity-id='" + id + "']").after(html);
        let $form = object.next().find('form');
        $form.find(':submit').click((event) => {
          event.preventDefault();

          $.ajax({
            type: "POST",
            url: milestone.url,
            processData: false,
            contentType: false,
            headers: {
              'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
            },
            data: new FormData($form[0]), // serializes the form's elements.
            success: () => {
              location.reload();
            },
            error: () => {
              location.reload()
            }
          });
        })
      }
    
    });
  });

});

