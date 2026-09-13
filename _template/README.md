# _template

The layout every module in this repository is copied from (PC-IAC-001). It is
a complete, working example — one user-assigned managed identity — so that
`terraform fmt`, tflint, and Trivy check the template itself. The rule
contracts and the Terraform checks skip directories whose name starts with `_`.

## Creating a module from it

1. Copy the directory to the module's name: `cp -R _template <module>`.
2. Replace the example identity in `main.tf`, `variables.tf`, `outputs.tf`,
   `sample/`, and `tests/` with the module's one service.
3. Keep every file, the governance variables, `additional_tags`, the
   governance tags on every taggable resource, and `provider = azurerm.project`
   on every resource.
4. Add the module to `release-please-config.json`, and, if it owns a type that
   PC-IAC-023 forbids elsewhere, to `iac-contracts.json`.
5. Describe inputs, outputs, and an example call in this README.
