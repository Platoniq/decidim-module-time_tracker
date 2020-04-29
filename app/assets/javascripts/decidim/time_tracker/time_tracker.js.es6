// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
//= require decidim/time_tracker/time_entry
//= require_self

$(function() {
  var $activities = $('.activity');
  var activities = {};

  $activities.each(function() {
    var id = $(this).data('activity-id');

    var last_time_entry = $("span[data-activity-id='elapsed_time_" + id + "'").data('time-entry');
    if (last_time_entry) {
      let time_entry = new TimeEntry();
      time_entry.id = last_time_entry.id;
      time_entry.setTimeStart = last_time_entry.time_start;
      activities[id] = time_entry;

      let elapsed_time = time_entry.getElapsedTime;
      activities[id].interval = setInterval( function() {
        elapsed_time += 100;
        var seconds = Math.floor(elapsed_time/ (1000));
        var minutes = Math.floor(seconds/ 60);
        var hour = Math.floor(minutes / 60);
        $("[data-activity-id='elapsed_time_" + id +"'").html( hour % 60 + "h " + minutes % 60 + "m " + seconds % 60 + "s");
      }, 100);
    }

    var button_start = $("button[id='start'][data-activity-id='" + id + "']");
    button_start.click(function() {
      var time_entry = activities[id];
      let elapsed_time;

      if (!time_entry) {
        time_entry = new TimeEntry();
        time_entry.start();
        activities[id] = time_entry;
        $.ajax({
          method: "POST",
          url: button_stop.data('endpoint'),
          contentType: "application/json",
          headers: {
            'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
          },
          data: JSON.stringify({ time_entry }),
          success: function(data, status) {
              time_entry.id = data.time_entry_id
            }
        });  
      }  else if (!time_entry.interval) {
        time_entry.resume();
      }

      elapsed_time = time_entry.getElapsedTime;
      if (!time_entry.interval) {
        activities[id].interval = setInterval( function() {
          elapsed_time += 100;
          var seconds = Math.floor(elapsed_time/ (1000));
          var minutes = Math.floor(seconds/ 60);
          var hour = Math.floor(minutes / 60);
          $("[data-activity-id='elapsed_time_" + id +"'").html( hour % 60 + "h " + minutes % 60 + "m " + seconds % 60 + "s");
        }, 100);
      }
    });

    var button_pause = $("button[id='pause'][data-activity-id='" + id + "']");
    button_pause.click(function() {
      var time_entry = activities[id];
      time_entry.pause();
      clearInterval(time_entry.interval);
      time_entry.interval = 0;
      $.ajax({
        method: "PATCH",
        url: button_stop.data('endpoint') + '/' + time_entry.id,
        contentType: "application/json",
        headers: {
          'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
        },
        data: JSON.stringify({ time_entry })
      });
    });

    var button_stop = $("button[id='stop'][data-activity-id='" + id + "']");
    button_stop.click(function() {
      var time_entry = activities[id];
      time_entry.stop();
      clearInterval(time_entry.interval);
      time_entry.interval = -1;
      $.ajax({
        method: "PATCH",
        url: button_stop.data('endpoint') + '/' + time_entry.id,
        contentType: "application/json",
        headers: {
          'X-CSRF-Token': $('meta[name=csrf-token]').attr('content')
        },
        data: JSON.stringify({ time_entry })
      });
    });
  });

});

