// Controls time events

export default class TimerApi { 
  constructor(startEndpoint, stopEndpoint) {
    this.startEndpoint = startEndpoint;
    this.stopEndpoint = stopEndpoint;
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute("content");
  }  

  start() {
    return new Promise((resolve, reject) => {
      fetch(this.startEndpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({})
      }).
        then((response) => {
          if (!response.ok) {
            throw new Error("Failed to start timer");
          }
          return response.json();
        }).
        then((data) => {
          resolve(data);
        }).
        catch((error) => {
          console.error("Error starting timer", error);
          reject(error.message || "Unknown error starting timer");
        });
    });
  }

  stop() {
    return new Promise((resolve, reject) => {
      fetch(this.stopEndpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({})
      }).
        then((response) => {
          if (!response.ok) {
            throw new Error("Failed to stop timer");
          }
          return response.json();
        }).
        then((data) => {
          resolve(data);
        }).
        catch((error) => {
          console.error("Error stopping timer", error);
          reject(error.message || "Unknown error stopping timer");
        });
    });
  }  
}
