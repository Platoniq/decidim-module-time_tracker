// Drives the badge form's levels section.
//
// Admins told us the old "1, 5, 15, 30" text box was the confusing part of
// setting up a badge, so the form now asks how many levels the badge has and
// fills in a sensible threshold for each one. The numbers stay editable for
// anyone who wants to tune them, but nobody has to invent a curve.

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("badge-levels");

  if (!container) {
    return;
  }

  const countField = document.getElementById("badge_levels_count");
  const metricField = document.getElementById("badge_metric");
  const rows = Array.from(container.querySelectorAll(".badge-level-row"));
  const curves = JSON.parse(container.dataset.defaultCurves || "{}");
  const units = JSON.parse(container.dataset.metricUnits || "{}");

  // Only rows up to the chosen level count are shown, and only those are
  // submitted — a disabled input is left out of the form data, which keeps the
  // thresholds array the same length as the level count.
  const showRowsUpTo = (count) => {
    rows.forEach((row) => {
      const level = parseInt(row.dataset.level, 10);
      const visible = level <= count;
      const input = row.querySelector(".badge-level-threshold");

      row.hidden = !visible;
      input.disabled = !visible;
    });
  };

  const currentMetric = () => {
    if (!metricField) {
      return "";
    }

    return metricField.value;
  };

  const currentCurve = () => curves[currentMetric()] || [];

  const applyUnitLabels = () => {
    const unit = units[currentMetric()] || "";

    rows.forEach((row) => {
      row.querySelector(".badge-level-row__unit").textContent = unit;
    });
  };

  // Called when the metric changes: the old curve's numbers rarely make sense
  // for the new one (25 hours vs 25 milestones), so they are replaced.
  const applyCurve = () => {
    const curve = currentCurve();

    rows.forEach((row, index) => {
      const input = row.querySelector(".badge-level-threshold");

      if (typeof curve[index] !== "undefined") {
        input.value = curve[index];
      }
    });
  };

  // Filling a newly revealed row that has no value yet, without touching the
  // numbers the admin already set on the rows above it.
  const fillBlankRows = () => {
    const curve = currentCurve();

    rows.forEach((row, index) => {
      const input = row.querySelector(".badge-level-threshold");

      if (input.value === "" && typeof curve[index] !== "undefined") {
        input.value = curve[index];
      }
    });
  };

  if (countField) {
    countField.addEventListener("change", () => {
      fillBlankRows();
      showRowsUpTo(parseInt(countField.value, 10));
    });
  }

  if (metricField) {
    metricField.addEventListener("change", () => {
      applyUnitLabels();
      applyCurve();
    });
  }

  applyUnitLabels();

  if (countField) {
    showRowsUpTo(parseInt(countField.value, 10));
  } else {
    showRowsUpTo(rows.length);
  }
});
