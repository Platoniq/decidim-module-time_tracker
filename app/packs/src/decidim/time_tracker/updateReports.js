const updateReports = () => {
  const params = new URLSearchParams(window.location.search);
  const activityId = params.get("activity");
  
  if (activityId) {
    const $activity = $(`[data-activity-id=${activityId}]`);

    if ($activity.length) {
      $("body,html").animate({
        scrollTop: ($activity.offset().top - $activity.height() / 2)
      },
      200
      );
    }
  }
}
export default updateReports;
