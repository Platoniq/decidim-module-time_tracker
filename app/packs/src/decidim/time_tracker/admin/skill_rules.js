// Makes the skill form say what it is building.
//
// The form has three numeric fields but only ever uses one or two of them,
// depending on how the skill is earned. Showing all three at once made admins
// guess which mattered, so the irrelevant ones are hidden and a plain-English
// summary of the rule is kept up to date underneath.

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("skill-rules");

  if (!container) {
    return;
  }

  const modes = Array.from(container.querySelectorAll("input[name='skill[earning_mode]']"));
  const activities = document.getElementById("skill-required-activities");
  const completions = document.getElementById("skill-required-completions");
  const hours = document.getElementById("skill-required-hours");
  const preview = document.getElementById("skill-rule-preview");
  const strings = JSON.parse(container.dataset.strings || "{}");

  const value = (wrapper) => wrapper?.querySelector("input")?.value.trim() || "";

  const isTimeSpent = () => modes.some((radio) => radio.checked && radio.value === "time_spent");

  const show = (wrapper, visible) => {
    if (!wrapper) {
      return;
    }
    wrapper.hidden = !visible;
    const input = wrapper.querySelector("input");
    // Left enabled but hidden, a stale number would still be submitted and
    // silently become part of the rule.
    if (input) {
      input.disabled = !visible;
    }
  };

  const fill = (template, values) =>
    Object.keys(values).reduce(
      (acc, key) => acc.replace(new RegExp(`%\\{${key}\\}`, "g"), values[key]),
      template || ""
    );

  const describe = () => {
    if (isTimeSpent()) {
      const tracked = value(hours);
      return tracked
        ? fill(strings.time_spent, { hours: tracked })
        : strings.incomplete;
    }

    const times = value(completions) || "1";
    const count = value(activities);
    const once = times === "1";
    let template = null;

    if (count) {
      template = once
        ? strings.some_one
        : strings.some_other;
    } else {
      template = once
        ? strings.all_one
        : strings.all_other;
    }

    return fill(template, { activities: count, count: times });
  };

  const render = () => {
    show(hours, isTimeSpent());
    show(activities, !isTimeSpent());
    show(completions, !isTimeSpent());
    if (preview) {
      preview.textContent = describe();
    }
  };

  modes.forEach((radio) => radio.addEventListener("change", render));
  [activities, completions, hours].forEach((wrapper) => {
    const input = wrapper?.querySelector("input");
    input?.addEventListener("input", render);
  });

  render();
});
