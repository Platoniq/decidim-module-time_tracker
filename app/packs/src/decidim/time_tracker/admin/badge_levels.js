// Drives the badge form: its levels, which parts of the rule apply, and the
// sentence that restates the rule as it is edited.
//
// Admins told us the old "1, 5, 15, 30" text box was the confusing part of
// setting up a badge, so the form asks how many levels the badge has and fills
// in a sensible threshold for each one. The numbers stay editable for anyone
// who wants to tune them, but nobody has to invent a curve.

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("badge-levels");

  if (!container) {
    return;
  }

  const countField = document.getElementById("badge_levels_count");
  const metrics = Array.from(container.querySelectorAll("input[name='badge[metric]']"));
  const rows = Array.from(container.querySelectorAll(".badge-level-row"));
  const curves = JSON.parse(container.dataset.defaultCurves || "{}");
  const units = JSON.parse(container.dataset.metricUnits || "{}");
  const labels = JSON.parse(container.dataset.metricLabels || "{}");
  const templates = JSON.parse(container.dataset.previewTemplates || "{}");
  const preview = document.getElementById("badge-rule-preview");
  const skillsField = document.getElementById("badge-skills-field");
  const tasksField = document.getElementById("badge-tasks-field");
  const taskList = document.getElementById("badge-task-list");
  const scopes = Array.from(container.querySelectorAll("input[name='badge_task_scope']"));
  const skillBoxes = Array.from(container.querySelectorAll("input[name='badge[skill_ids][]']"));
  const taskBoxes = Array.from(container.querySelectorAll("input[name='badge[task_ids][]']"));

  const currentMetric = () => metrics.find((radio) => radio.checked)?.value || "";
  const isRequiredSkills = () => currentMetric() === "required_skills";
  const restrictedToTasks = () => scopes.some((radio) => radio.checked && radio.value === "some");
  const currentCurve = () => curves[currentMetric()] || [];
  const checkedLabels = (boxes) => boxes.filter((box) => box.checked && !box.disabled).map((box) => box.dataset.label);

  // Inputs in a hidden part of the form are disabled too, so a choice that no
  // longer applies is not submitted along with the ones that do.
  const enable = (boxes, enabled) => boxes.forEach((box) => {
    box.disabled = !enabled;
  });

  // Only rows up to the chosen level count are shown, and only those are
  // submitted, which keeps the thresholds array the same length as the count.
  const showRowsUpTo = (count) => {
    rows.forEach((row) => {
      const visible = parseInt(row.dataset.level, 10) <= count;
      row.hidden = !visible;
      row.querySelector(".badge-level-threshold").disabled = !visible;
    });
  };

  const applyUnitLabels = () => {
    const unit = units[currentMetric()] || "";
    rows.forEach((row) => {
      row.querySelector(".badge-level-row__unit").textContent = unit;
    });
  };

  // When the metric changes the old curve's numbers rarely make sense for the
  // new one (25 hours against 25 milestones), so they are replaced.
  const applyCurve = () => {
    const curve = currentCurve();
    rows.forEach((row, index) => {
      if (typeof curve[index] !== "undefined") {
        row.querySelector(".badge-level-threshold").value = curve[index];
      }
    });
  };

  // Fills a newly revealed row that has no value yet, without touching the
  // numbers already set on the rows above it.
  const fillBlankRows = () => {
    const curve = currentCurve();
    rows.forEach((row, index) => {
      const input = row.querySelector(".badge-level-threshold");
      if (input.value === "" && typeof curve[index] !== "undefined") {
        input.value = curve[index];
      }
    });
  };

  const fill = (template, values) =>
    Object.keys(values).reduce(
      (acc, key) => acc.replace(new RegExp(`%\\{${key}\\}`, "g"), values[key]),
      template || ""
    );

  const describe = () => {
    const chosenLevels = rows.
      filter((row) => !row.hidden).
      map((row) => row.querySelector(".badge-level-threshold").value.trim()).
      filter(Boolean);
    const levelText = fill(templates.levels, { levels: chosenLevels.join(" → ") });

    if (isRequiredSkills()) {
      const names = checkedLabels(skillBoxes);
      return names.length
        ? `${fill(templates.required_skills, { skills: names.join(", ") })} ${levelText}`
        : templates.no_skills;
    }

    const metricLabel = labels[currentMetric()] || "";
    const taskNames = restrictedToTasks()
      ? checkedLabels(taskBoxes)
      : [];
    const base = taskNames.length
      ? fill(templates.restricted, { metric: metricLabel, tasks: taskNames.join(", ") })
      : fill(templates.all_tasks, { metric: metricLabel });

    return `${base} ${levelText}`;
  };

  // A required_skills badge ignores the task restriction, and every other
  // metric ignores the skill list, so only the one that matters is shown.
  const render = () => {
    const skillsBased = isRequiredSkills();
    if (skillsField) {
      skillsField.hidden = !skillsBased;
    }
    if (tasksField) {
      tasksField.hidden = skillsBased;
    }
    if (taskList) {
      taskList.hidden = !restrictedToTasks();
    }
    enable(skillBoxes, skillsBased);
    enable(taskBoxes, !skillsBased && restrictedToTasks());

    if (preview) {
      preview.textContent = describe();
    }
  };

  countField?.addEventListener("change", () => {
    fillBlankRows();
    showRowsUpTo(parseInt(countField.value, 10));
    render();
  });

  metrics.forEach((radio) => radio.addEventListener("change", () => {
    applyUnitLabels();
    applyCurve();
    render();
  }));

  [...scopes, ...skillBoxes, ...taskBoxes].forEach((input) => input.addEventListener("change", render));
  rows.forEach((row) => row.querySelector(".badge-level-threshold")?.addEventListener("input", render));

  applyUnitLabels();
  showRowsUpTo(countField
    ? parseInt(countField.value, 10)
    : rows.length);
  render();
});
