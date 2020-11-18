((exports) => {
  const { createFieldDependentInputs } = exports.DecidimAdmin;

  const $assignationType = $("#assignation_existing_user");

  createFieldDependentInputs({
    controllerField: $assignationType,
    wrapperSelector: ".user-fields",
    dependentFieldsSelector: ".user-fields--email",
    dependentInputSelector: "input",
    enablingCondition: ($field) => {
      return $field.val() === "false"
    }
  });

  createFieldDependentInputs({
    controllerField: $assignationType,
    wrapperSelector: ".user-fields",
    dependentFieldsSelector: ".user-fields--name",
    dependentInputSelector: "input",
    enablingCondition: ($field) => {
      return $field.val() === "false"
    }
  });

  createFieldDependentInputs({
    controllerField: $assignationType,
    wrapperSelector: ".user-fields",
    dependentFieldsSelector: ".user-fields--user-picker",
    dependentInputSelector: "input",
    enablingCondition: ($field) => {
      return $field.val() === "true"
    }
  });
})(window);
