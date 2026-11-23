# Resolving context and recording its use

The task's owner signs a context requirement; an admitted caller sends a resolve request; Scope answers with a signed bundle; the bound bytes are read back with a read request; the caller reports what it used and Scope receipts the report. The rules are on [Episodes and use](../episodes-and-use.md) and [Contracts](../contracts.md).

The execution-binding fields below illustrate the deferred execution branch. Here `episode_identity` is a placeholder for the whole issuing contract, with no selected wire shape. The independent schemas omit execution bindings and reject requests that supply them. [Publication boundary](../contracts.md)

```text
ContextRequirementV1
  schema_id
  schema_sha256
  context_requirement_id
  task_ref
  task_class                    context_critical | context_enhanced |
                                context_independent
  principal_scope
  controller_scope
  relationship_scope?
  role_ref
  purpose
  classification_ceiling
  required_sources[] {
    source_id
    consistency_class
    freshness_requirement
  }
  optional_sources[] {
    source_id
    consistency_class
    freshness_requirement
  }
  token_or_size_budget
  permitted_context_variants[] exact_bundle | authorized_degraded |
                                context_independent
  degradation_policy_ref?
  degradation_policy_sha256?
  authority_ref
  authority_sha256
  issued_at
  expires_at
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_context_requirement_sha256
  signature

ResolveRequestV1
  schema_id
  schema_sha256
  request_id
  caller_identity
  episode_identity?               # issuing contract pending
  execution_attempt_id?
  execution_authorization_ref?
  execution_authorization_sha256?
  execution_reservation_ref?
  execution_reservation_sha256?
  execution_owner_fence_ref?
  execution_owner_fence_sha256?
  context_requirement_ref?
  context_requirement_sha256?
  principal_scope
  controller_scope
  relationship_scope?
  role_ref
  task_ref
  query
  required_sources
  optional_sources
  classification_ceiling
  freshness_requirement
  token_or_size_budget
  purpose
  requested_at
```

The authority frontier is embedded in every signed result that depends on a standalone grant or import delegation, recording exactly which revocation head was checked.

```text
ScopeAuthorityFrontierV1
  authority_principal_id
  subject_kind                  caller_grant | import_delegation
  subject_id
  subject_ref
  subject_sha256
  checked_revocation_epoch
  checked_revocation_ref?
  checked_revocation_sha256?
  checkpoint_ref
  checkpoint_sha256
  checked_at
```

```text
ContextBundleV1
  schema_id
  schema_sha256
  bundle_id
  request_id
  admission_binding {          # exactly one variant
    standalone? {
      admission_ref
      admission_sha256
    }
    pale? {
      common_request_ref
      canonical_request_sha256
      federation_request_admission_ref?
      federation_request_admission_sha256?
    }
  }
  scope_authority_frontier?      # ScopeAuthorityFrontierV1; caller_grant only
  bundle_digest
  retrieval_decision_ref
  retrieval_decision_sha256
  episode_identity?               # issuing contract pending
  execution_attempt_id?
  execution_authorization_ref?
  execution_authorization_sha256?
  execution_reservation_ref?
  execution_reservation_sha256?
  execution_owner_fence_ref?
  execution_owner_fence_sha256?
  context_requirement_ref?
  context_requirement_sha256?
  principal_scope
  controller_scope
  relationship_scope?
  role_ref
  purpose
  classification_ceiling
  visibility_policy_ref
  visibility_policy_sha256
  consistency_class
  source_snapshots[] {
    source_snapshot_ref
    source_snapshot_sha256
    source_owner
    source_namespace
    source_generation
    observed_at
    valid_through
  }
  semantic_items[] {
    item_ref
    item_sha256
    semantic_owner
    source_record_refs[] {
      source_record_ref
      source_version
      content_digest
    }
    authority_class
    lifecycle_namespace
    lifecycle_state
    classification
    visibility_ref
    visibility_sha256
    observed_at
    valid_through
    revision
  }
  unresolved_requirements[] {
    requirement_ref
    requirement_sha256
    reason
    retryable
  }
  omissions[] {
    requirement_or_item_ref
    reason
    source_snapshot_ref?
    retryable
  }
  provenance_graph_ref
  provenance_graph_sha256
  generated_at
  valid_through
  limitations[] {
    limitation_code
    bounded_detail?
    evidence_ref?
    evidence_sha256?
  }
  signing_authority_binding      # Scope's mode-specific authority; see Contracts
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  signature
```

```text
ContextBundleReadRequestV1
  schema_id
  schema_sha256
  read_request_id
  context_bundle_ref
  context_bundle_digest
  execution_binding? {         # present as one complete object or absent
    episode_identity               # issuing contract pending
    execution_attempt_id
    execution_authorization_ref
    execution_authorization_sha256
    execution_reservation_ref
    execution_reservation_sha256
    execution_owner_fence_ref
    execution_owner_fence_sha256
    execution_handoff_ref
    execution_handoff_sha256
    context_requirement_ref
    context_requirement_sha256
    context_binding_sha256
  }
  caller_identity
  purpose
  requested_at
```

```text
ContextUseReportV1
  schema_id
  schema_sha256
  report_id
  context_bundle_ref
  bundle_id
  bundle_digest
  execution_binding? {         # present as one complete object or absent
    episode_identity               # issuing contract pending
    execution_attempt_id
    execution_authorization_ref
    execution_authorization_sha256
    execution_reservation_ref
    execution_reservation_sha256
    execution_owner_fence_ref
    execution_owner_fence_sha256
    execution_handoff_ref
    execution_handoff_sha256
    context_requirement_ref
    context_requirement_sha256
    context_binding_sha256
  }
  caller_identity
  use_scope {
    principal_scope
    controller_scope
    relationship_scope?
    role_ref
    purpose
    classification_ceiling
  }
  task_ref?
  consumed_items[] {
    item_ref
    item_sha256
  }
  ignored_items[] {
    item_ref
    item_sha256
    reason
  }
  generated_artifacts[] {
    artifact_ref
    artifact_sha256
    artifact_schema_id
    artifact_schema_sha256
  }
  observed_staleness[] {
    item_ref
    item_sha256
    evidence_ref
    evidence_sha256
    reason
  }
  used_at
```

```text
ContextUseReceiptV1
  schema_id
  schema_sha256
  receipt_id
  admission_binding {          # exactly one variant
    standalone? {
      admission_ref
      admission_sha256
    }
    pale? {
      common_request_ref
      canonical_request_sha256
      federation_request_admission_ref?
      federation_request_admission_sha256?
    }
  }
  scope_authority_frontier?      # ScopeAuthorityFrontierV1; caller_grant only
  report_ref
  report_sha256
  context_bundle_ref
  bundle_id
  bundle_digest
  execution_binding? {         # exactly echoes the accepted report
    episode_identity               # issuing contract pending
    execution_attempt_id
    execution_authorization_ref
    execution_authorization_sha256
    execution_reservation_ref
    execution_reservation_sha256
    execution_owner_fence_ref
    execution_owner_fence_sha256
    execution_handoff_ref
    execution_handoff_sha256
    context_requirement_ref
    context_requirement_sha256
    context_binding_sha256
  }
  caller_identity
  use_scope {                    # exactly echoes the accepted report
    principal_scope
    controller_scope
    relationship_scope?
    role_ref
    purpose
    classification_ceiling
  }
  task_ref?
  accepted_evidence? {         # required for accepted/duplicate; forbidden for rejected
    consumed_items[] {
      item_ref
      item_sha256
    }
    generated_artifacts[] {
      artifact_ref
      artifact_sha256
      artifact_schema_id
      artifact_schema_sha256
    }
    accepted_at
  }
  disposition                 accepted | duplicate | rejected
  duplicate_of_receipt_ref?
  duplicate_of_receipt_sha256?
  disposition_reason?
  recorded_at
  signing_authority_binding      # Scope's mode-specific authority; see Contracts
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_receipt_sha256
  signature
```

Part of [Record reference](../record-reference.md).
