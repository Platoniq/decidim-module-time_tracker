// Talks to the start and stop endpoints of one activity.
//
// Both answer 200 with an `error` key for the harmless cases (a counter that
// is already running or already stopped), and 422 with the reason when the
// action is refused — that reason is what the volunteer is shown.

const csrfToken = () => document.querySelector("meta[name=csrf-token]")?.getAttribute("content");

const post = (url) =>
  fetch(url, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: "{}"
  }).then((response) =>
    response.json().
      catch(() => ({})).
      then((data) => {
        if (!response.ok) {
          throw new Error(data.error || data.message || response.statusText);
        }
        return data;
      })
  );

export default class TimerApi {
  constructor(startEndpoint, stopEndpoint) {
    this.startEndpoint = startEndpoint;
    this.stopEndpoint = stopEndpoint;
  }

  start() {
    return post(this.startEndpoint);
  }

  stop() {
    return post(this.stopEndpoint);
  }
}
