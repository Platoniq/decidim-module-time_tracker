$(() => {
  $(document).ready(( ) => {
    const params = new URLSearchParams(window.location.search);
    const activity_id = params.get('activity');
    
    if (activity_id) {
      const $activity = $(`[data-activity-id=${activity_id}]`);

      if ($activity.length) {
        $("body,html").animate({
            scrollTop: ($activity.offset().top - $activity.height() / 2)
          },
          200
        );
      }
    }
  });
});

