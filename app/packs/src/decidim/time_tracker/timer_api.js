// Controlls time events

export default class TimerApi { 
  constructor(startEndpoint, stopEndpoint) {
    this.startEndpoint = startEndpoint;
    this.stopEndpoint = stopEndpoint;
    this.csrfToken = $("meta[name=csrf-token]").attr("content");
  }

  start() {
    const promise = $.Deferred(); // eslint-disable-line new-cap

    $.ajax({
      method: "POST",
      url: this.startEndpoint,
      contentType: "application/json",
      headers: {
        "X-CSRF-Token": this.csrfToken
      },
      success: (data) => {
        promise.resolve(data);
      },
      error: (jq) => {
        const error = (jq.responseJSON && jq.responseJSON.error) || "Unkown error starting timer";
        console.error("error starting time", error);
        promise.reject(error);
      }
    });

    return promise;
  }
  
  stop() {
    const promise = $.Deferred(); // eslint-disable-line new-cap

    $.ajax({
      method: "POST",
      url: this.stopEndpoint,
      contentType: "application/json",
      headers: {
        "X-CSRF-Token": this.csrfToken
      },
      success: (data) => {
        promise.resolve(data);
      },
      error: (jq) => {
        const error = (jq.responseJSON && jq.responseJSON.error) || "Unkown error stopping timer";
        console.error("error stopping time", error);
        promise.reject(error);
      }
    });

    return promise;
  }
}
