const updateReports = () => {
  const params = new URLSearchParams(window.location.search);
  const activityId = params.get("activity");

  if (activityId) {
    const activity = document.querySelector(`[data-activity-id="${activityId}"]`);

    if (activity) {
      const scrollToPosition = activity.offsetTop - (activity.offsetHeight / 2);

      window.scrollTo({
        top: scrollToPosition,
        behavior: "smooth"
      });
    }
  }
}

export default updateReports;
