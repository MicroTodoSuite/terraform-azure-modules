# Infrastructure-as-Code Exceptions

Findings of the rule contracts, tflint, Trivy, or SonarCloud that the team has
decided to accept. A row waives a contract finding only when it carries a
reason and an expiry; the format is defined in
`microservice-app-ai-agents/rules/iac/README.md`. Rows for tflint, Trivy, and
SonarCloud record the decision behind a suppression made in that tool or in
the code (`NOSONAR`, `.trivyignore`), which must cite the row. Each row is added
in its own reviewed pull request.

| Rule | Path | Resource | Reason | Expiry |
| --- | --- | --- | --- | --- |
| `terraform:S6329` | `container-registry` | `azurerm_container_registry.this` | Maintainer-delegated lead decision of 2026-09-21: retain the Standard SKU and public endpoint. Premium costs about USD 50 per 30 days against the Azure for Students credit of USD 100 for 12 months, and its [Premium-only public IP rules](https://learn.microsoft.com/azure/container-registry/container-registry-access-selected-networks) cannot admit the GitHub-hosted ECR-to-ACR mirror runners because they have no fixed egress address. The compensating control is identity: [Microsoft Entra authentication](https://learn.microsoft.com/azure/container-registry/container-registry-authentication), with the admin user and anonymous pull disabled, no static credentials, digest-pinned pulls, and T133 signature verification. | Revisit when the mirror has fixed egress and Premium fits the DR budget, or when Standard gains an applicable network-isolation feature. |
