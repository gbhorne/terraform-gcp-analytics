# Architecture Decision Records — Lab 02: Terraform IaC

## ADR-01: Modular Terraform Structure

**Decision:** Split infrastructure into 6 independent modules.

**Context:** A single main.tf becomes unmanageable at scale. The platform spans 6 GCP services with 49 resources.

**Rationale:**
- Each module can be developed, tested, and versioned independently
- Teams can own specific modules (data team owns bigquery, platform team owns monitoring)
- Modules are reusable across projects
- `depends_on` ensures correct ordering without tight coupling

**Trade-off:** More files to navigate, but vastly better maintainability.

---

## ADR-02: for_each Over count for Resource Iteration

**Decision:** Use `for_each` with maps/sets instead of `count` with lists.

**Context:** `count` uses numeric indices (resource[0]), while `for_each` uses meaningful keys (resource["transactions"]).

**Rationale:**
- Adding or removing items from a count list shifts all indices, causing unnecessary destroys
- `for_each` keys are stable — adding a new topic does not affect existing ones
- State references are human-readable: `google_pubsub_topic.topics["retail-transactions"]`

---

## ADR-03: Environment Isolation via tfvars

**Decision:** Use separate .tfvars files per environment rather than Terraform workspaces.

**Context:** Workspaces share the same backend. For true isolation (separate state, different projects), tfvars is more explicit.

**Rationale:**
- Each environment gets its own GCP project ID and bucket name
- No risk of accidentally applying dev changes to prod
- CI/CD pipelines select the right tfvars: `terraform apply -var-file=environments/prod/prod.tfvars`

---

## ADR-04: API Enablement as a Terraform Module

**Decision:** Manage GCP API enablement in Terraform rather than assuming APIs are pre-enabled.

**Context:** Many tutorials skip API enablement, requiring manual gcloud commands first.

**Rationale:**
- `terraform apply` on a fresh project works without any manual steps
- `disable_on_destroy = false` prevents terraform destroy from disabling APIs
- `disable_dependent_services = false` prevents cascading disables

---

## ADR-05: PII Taxonomy with Hierarchical Policy Tags

**Decision:** Define a 3-tier PII classification taxonomy in Data Catalog.

**Context:** The retail platform contains customer PII. Column-level security requires policy tags.

**Rationale:**
- High Sensitivity (email, phone, DOB): Direct identifiers
- Medium Sensitivity (name, address): Quasi-identifiers
- Low Sensitivity (gender, loyalty tier): Demographics
- Tags created by Terraform; column binding requires IAM (production step)

---

## ADR-06: Monitoring as Code

**Decision:** Define dashboards and alert policies in Terraform, not manually in Console.

**Context:** Manually created dashboards drift silently and are invisible to version control.

**Rationale:**
- Dashboards are reproducible across environments
- Alert thresholds are code-reviewed before deployment
- `terraform plan` detects manual changes to alert thresholds
- Dashboard JSON is verbose but fully declarative
