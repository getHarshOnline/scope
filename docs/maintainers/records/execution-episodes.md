# Execution episodes

These open, handoff-bind and expiry sketches preserve the transition and receipt design. The successor identity and its issuing contract remain open. The entire family stays out of the independent manifest. [Episodes and use](../episodes-and-use.md)

```text
EpisodeOpenRequestV1
  schema_id
  schema_sha256
  open_request_id
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  episode_identity               # issuing contract pending
  principal_scope
  controller_scope
  relationship_scope?
  lifecycle_namespace
  lifecycle_state
  execution_reservation_ref
  execution_reservation_sha256
  context_requirement_ref
  context_requirement_sha256
  execution_owner_fence_ref
  execution_owner_fence_sha256
  expiry_policy_ref
  expiry_policy_sha256
  opened_at
  clock_basis_ref
  clock_basis_sha256

EpisodeOpenReceiptV1
  schema_id
  schema_sha256
  open_receipt_id
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  open_request_ref
  open_request_sha256
  pale_admission_binding {
    common_request_ref
    canonical_request_sha256
    federation_request_admission_ref?
    federation_request_admission_sha256?
  }
  episode_identity               # issuing contract pending
  execution_owner_fence_ref
  execution_owner_fence_sha256
  committed_episode_ref?
  committed_episode_sha256?
  committed_revision?
  disposition                   committed | conflict | rejected
  disposition_reason?
  recorded_at
  signing_authority_binding      # Pale's SigningAuthorityBindingV1
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_open_receipt_sha256
  signature

EpisodeHandoffBindRequestV1
  schema_id
  schema_sha256
  bind_request_id
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  episode_identity               # issuing contract pending
  expected_episode_revision
  expected_episode_sha256
  execution_reservation_ref
  execution_reservation_sha256
  execution_handoff_ref
  execution_handoff_sha256
  context_requirement_ref
  context_requirement_sha256
  execution_owner_fence_ref
  execution_owner_fence_sha256
  context_variant               exact_bundle | authorized_degraded
  context_binding_sha256
  requested_at

EpisodeHandoffBindReceiptV1
  schema_id
  schema_sha256
  bind_receipt_id
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  bind_request_ref
  bind_request_sha256
  pale_admission_binding {
    common_request_ref
    canonical_request_sha256
    federation_request_admission_ref?
    federation_request_admission_sha256?
  }
  episode_identity               # issuing contract pending
  execution_owner_fence_ref
  execution_owner_fence_sha256
  execution_handoff_ref
  execution_handoff_sha256
  committed_episode_ref?
  committed_episode_sha256?
  committed_revision?
  disposition                   committed | conflict | rejected
  disposition_reason?
  recorded_at
  signing_authority_binding      # Pale's SigningAuthorityBindingV1
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_bind_receipt_sha256
  signature

EpisodeExpiryRequestV1
  schema_id
  schema_sha256
  expiry_request_id
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  episode_identity               # issuing contract pending
  expected_episode_revision
  expected_episode_sha256
  expiry_policy_ref
  expiry_policy_sha256
  evaluated_at
  clock_basis_ref
  clock_basis_sha256
  reason_code

EpisodeV1
  schema_id
  schema_sha256
  episode_identity               # issuing contract pending
  execution_attempt_id
  execution_authorization_ref
  execution_authorization_sha256
  revision
  expected_previous_revision?
  previous_episode_sha256?
  status                        open | closed | expired
  lifecycle_namespace
  lifecycle_state
  principal_scope
  controller_scope
  relationship_scope?
  source_records[] {
    source_record_ref
    source_version
    content_digest
  }
  provisional_open_evidence {
    execution_attempt_id
    execution_authorization_ref
    execution_authorization_sha256
    execution_reservation_ref
    execution_reservation_sha256
    context_requirement_ref
    context_requirement_sha256
    execution_owner_fence_ref
    execution_owner_fence_sha256
  }
  context_evidence[] {          # length 0 at provisional revision 1; exactly
                                # 1 after the sole handoff bind; immutable later
    exact_bundle? {
      execution_reservation_ref
      execution_reservation_sha256
      execution_handoff_ref
      execution_handoff_sha256
      context_requirement_ref
      context_requirement_sha256
      context_binding_sha256
      context_bundle_ref
      context_bundle_digest
      context_use_receipts[] {
        receipt_ref
        receipt_sha256
      }
    }
    authorized_degraded? {
      execution_reservation_ref
      execution_reservation_sha256
      execution_handoff_ref
      execution_handoff_sha256
      context_requirement_ref
      context_requirement_sha256
      context_binding_sha256
      degradation_receipt_ref
      degradation_receipt_sha256
    }
  }
  terminal_owner_event_ref?
  terminal_owner_event_digest?
  outcome_evidence[] {
    evidence_ref
    evidence_sha256
    evidence_schema_id
    evidence_schema_sha256
    evidence_timing             timely | late_after_expiry
    late_evidence_review_ref?
    late_evidence_review_sha256?
  }
  derived_score_projection_ref?
  derived_score_projection_sha256?
  opened_at
  expires_at
  expiry_policy_ref
  expiry_policy_sha256
  expiry_transition_request_ref?
  expiry_transition_request_sha256?
  expiry_reason_code?
  expiry_clock_basis_ref?
  expiry_clock_basis_sha256?
  updated_at
  closed_at?
  expired_at?
  signing_authority_binding      # Pale's SigningAuthorityBindingV1
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_episode_sha256
  signature
```

Part of [Record reference](../record-reference.md).
