// The check-out survey (policy tracker): opened after a volunteer stops a
// timer, when the component has it switched on. Resolves once the dialog is
// closed, whether the survey was sent or skipped, so the caller can carry on
// (show the "Leave your mark" milestone form).

const csrfToken = () => document.querySelector("meta[name=csrf-token]")?.getAttribute("content");

const setDonationFields = (dialog, enabled) => {
  dialog.querySelectorAll("[data-checkout-fields] select, [data-checkout-fields] input, [data-checkout-fields] fieldset").forEach((field) => {
    field.disabled = !enabled;
  });
  dialog.querySelector("[data-checkout-fields]")?.classList.toggle("is-enabled", enabled);
};

const setUpDialog = (dialog) => {
  if (dialog.dataset.ready) {
    return;
  }
  dialog.dataset.ready = "true";

  const consent = dialog.querySelector("[data-checkout-consent]");
  const decline = dialog.querySelector("[data-checkout-decline]");
  consent?.addEventListener("change", () => {
    if (consent.checked && decline) {
      decline.checked = false;
    }
    setDonationFields(dialog, consent.checked);
  });
  decline?.addEventListener("change", () => {
    if (decline.checked && consent) {
      consent.checked = false;
      setDonationFields(dialog, false);
    }
  });
};

const timeEventId = (stopResponse) => {
  const raw = stopResponse?.timeEvent;
  try {
    return (typeof raw === "string"
      ? JSON.parse(raw)
      : raw)?.id;
  } catch {
    return null;
  }
};

/**
 * Opens the check-out survey for the time entry a Stop just saved.
 *
 * @param {Object} options - what the dialog needs
 * @param {string} options.endpoint - the activity's checkout endpoint (unset when the survey is off)
 * @param {Object} options.stopResponse - the JSON the stop endpoint answered
 * @param {string} options.activityTitle - shown in the dialog title
 * @param {Function} options.onNotice - shows the confirmation message
 * @returns {Promise} resolves when the dialog closes (sent or skipped)
 */
export default function openCheckoutSurvey({ endpoint, stopResponse, activityTitle, onNotice }) {
  const dialog = document.getElementById("time-tracker-checkout");
  const id = timeEventId(stopResponse);
  if (!dialog || !endpoint || !id || typeof dialog.showModal !== "function") {
    return Promise.resolve();
  }

  setUpDialog(dialog);
  const form = dialog.querySelector("[data-checkout-form]");
  const error = dialog.querySelector("[data-checkout-error]");
  const submit = dialog.querySelector("[data-checkout-submit]");

  // A fresh survey for this time entry; the donation answers stay as they were.
  form.querySelectorAll(".time-tracker__checkout-section:not([data-checkout-donation]) input").forEach((input) => {
    input.checked = false;
  });
  dialog.querySelector("[data-checkout-time-event]").value = id;
  dialog.querySelector("[data-checkout-activity]").textContent = activityTitle
    ? `“${activityTitle}”`
    : "";
  error.hidden = true;

  return new Promise((resolve) => {
    // One set of listeners per opening, all removed together when it closes.
    const listeners = new AbortController();
    const close = () => {
      listeners.abort();
      dialog.close();
      resolve();
    };

    form.addEventListener("submit", (event) => {
      event.preventDefault();
      submit.disabled = true;
      fetch(endpoint, {
        method: "POST",
        credentials: "same-origin",
        headers: { "Accept": "application/json", "X-CSRF-Token": csrfToken() },
        body: new FormData(form)
      }).
        then((response) => response.json().catch(() => ({})).then((data) => ({ ok: response.ok, data }))).
        then(({ ok, data }) => {
          if (!ok) {
            error.textContent = data.message || "";
            error.hidden = false;
            return;
          }
          // Asked once: after donating (or declining) the section goes away.
          if (data.dataAnswered) {
            dialog.querySelector("[data-checkout-donation]")?.remove();
          }
          onNotice?.(data.message);
          close();
        }).
        catch(() => {
          error.hidden = false;
        }).
        finally(() => {
          submit.disabled = false;
        });
    }, { signal: listeners.signal });

    dialog.querySelectorAll("[data-checkout-skip]").forEach((button) => button.addEventListener("click", close, { signal: listeners.signal }));
    dialog.addEventListener("cancel", close, { signal: listeners.signal });
    dialog.showModal();
  });
}
