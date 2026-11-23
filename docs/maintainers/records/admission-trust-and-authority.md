# Admission, trust and authority

Standalone admission roots, recovery policies and proofs, resource-owner trust records, caller grants, request admissions, revocations, authority checkpoints, the internal durable-state checkpoint, and the one mutation request and receipt through which all of them are written. The rules are on [Admission and trust](../admission-and-trust.md).

```text
ScopeAdmissionAuthorityRootV1
  schema_id
  schema_sha256
  authority_root_id
  authority_principal_id
  authority_key_id
  authority_key_epoch
  authority_public_key
  permitted_record_kinds[]     caller_grant | authority_revocation |
                               authority_checkpoint |
                               service_output_signing_authority |
                               resource_owner_trust |
                               resource_owner_recovery_policy |
                               resource_owner_recovery_proof |
                               import_delegation
  issued_at
  expires_at?
  canonical_authority_root_sha256
  self_signature

ScopeResourceOwnerRecoveryPolicyV1
  schema_id
  schema_sha256
  recovery_policy_id
  resource_owner_id
  policy_epoch
  eligible_signers[] {
    signer_identity
    signer_key_id
    signer_key_epoch
    signer_public_key
  }
  threshold
  proof_validity_seconds
  issued_at
  expires_at?
  previous_policy_ref?
  previous_policy_sha256?
  issuer_key_id
  issuer_key_epoch
  canonical_recovery_policy_sha256
  signature

ScopeResourceOwnerRecoveryProofV1
  schema_id
  schema_sha256
  recovery_proof_id
  resource_owner_id
  prior_trust_record_ref
  prior_trust_record_sha256
  recovery_policy_ref
  recovery_policy_sha256
  new_key_id
  new_key_epoch
  new_public_key
  nonce
  issued_at
  expires_at
  signatures[] {
    signer_identity
    signer_key_id
    signer_key_epoch
    signature
  }
  canonical_recovery_proof_sha256

ScopeResourceOwnerTrustRecordV1
  schema_id
  schema_sha256
  trust_record_id
  resource_owner_id
  trust_record_revision
  key_id
  key_epoch
  public_key
  state                         active | revoked
  permitted_source_namespaces[]
  principal_scopes[]
  controller_scopes[]
  relationship_scopes[]
  classification_ceiling
  recovery_policy_ref
  recovery_policy_sha256
  transition_mode               initial | normal_rotation | recovery |
                                policy_update | revocation
  previous_trust_record_ref?
  previous_trust_record_sha256?
  recovery_proof_ref?
  recovery_proof_sha256?
  issued_at
  expires_at?
  old_key_signature?
  new_key_signature?
  canonical_trust_record_sha256

ScopeStandaloneCallerGrantV1
  schema_id
  schema_sha256
  grant_id
  subject_identity
  subject_key_id
  subject_key_epoch
  subject_public_key
  principal_scopes[]
  controller_scopes[]
  relationship_scopes[]
  allowed_role_refs[]
  allowed_purposes[]
  allowed_operations[]         resolve_context | read_context_bundle |
                               report_context_use
  classification_ceiling
  issued_at
  expires_at
  non_transferable             # always true
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_grant_sha256
  signature

ScopeStandaloneRequestAdmissionV1
  schema_id
  schema_sha256
  admission_id
  caller_grant_ref
  caller_grant_sha256
  request_id
  operation_schema_id
  operation_schema_sha256
  operation_body_sha256
  issued_at
  expires_at
  signer_identity
  signer_key_id
  signer_key_epoch
  canonical_admission_sha256
  signature

ScopeAuthorityRevocationV1
  schema_id
  schema_sha256
  revocation_id
  authority_principal_id
  subject_kind                 caller_grant | import_delegation
  subject_id
  subject_ref
  subject_sha256
  revocation_epoch
  previous_revocation_ref?
  previous_revocation_sha256?
  previous_revocation_epoch?
  effective_at
  reason_code
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_revocation_sha256
  signature

ScopeAuthorityCheckpointV1
  schema_id
  schema_sha256
  checkpoint_id
  checkpoint_epoch
  previous_checkpoint_ref?
  previous_checkpoint_sha256?
  authority_principal_id
  authority_heads_root_sha256
  covered_subject_count
  generated_at
  issuer_key_id
  issuer_key_epoch
  canonical_checkpoint_sha256
  signature

ScopeDurableStateCheckpointV1     # Scope-internal; not a published record
  schema_id
  schema_sha256
  state_checkpoint_id
  state_checkpoint_sequence
  previous_state_checkpoint_ref?
  previous_state_checkpoint_sha256?
  control_incarnation_id
  authority_checkpoint_ref
  authority_checkpoint_sha256
  authority_checkpoint_epoch
  controller_writer_generations_root_sha256
  active_import_profile_heads_root_sha256
  active_source_namespace_heads_root_sha256
  semantic_namespace_heads_root_sha256
  semantic_tombstone_root_sha256
  source_import_inbox_frontier_root_sha256
  context_use_frontier_root_sha256
  episode_frontier_root_sha256
  owner_event_inbox_outbox_frontier_root_sha256
  website_source_generation_policy_heads_root_sha256
  migration_schema_head_ref
  migration_schema_head_sha256
  committed_transaction_sequence
  committed_at
  canonical_durable_state_checkpoint_sha256
  scope_signer_key_id
  scope_signer_key_epoch
  signature

ScopeAuthorityMutationRequestV1
  schema_id
  schema_sha256
  mutation_id
  operation                    bootstrap_authority | admit_caller_grant |
                               register_service_output_signer |
                               rotate_service_output_signer |
                               recover_service_output_signer |
                               retire_service_output_signer |
                               register_resource_owner |
                               rotate_resource_owner |
                               recover_resource_owner |
                               update_resource_owner_policy |
                               revoke_resource_owner |
                               admit_import_delegation | revoke_authority
  candidate_records[] {
    candidate_record_schema_id
    candidate_record_ref
    candidate_record_sha256
  }
  candidate_set_sha256
  expected_heads[] {
    head_kind
    scope_key_sha256
    expected_head_ref?
    expected_head_sha256?
    expected_head_epoch?
  }
  issued_at
  expires_at
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_mutation_request_sha256
  signature

ScopeAuthorityMutationReceiptV1
  schema_id
  schema_sha256
  receipt_id
  mutation_request_ref
  mutation_request_sha256
  disposition                 committed | rejected | conflict
  admitted_records[] {
    admitted_record_schema_id
    admitted_record_ref
    admitted_record_sha256
  }
  transitioned_heads[] {
    head_kind
    scope_key_sha256
    previous_head_ref?
    previous_head_sha256?
    previous_head_epoch?
    new_head_ref
    new_head_sha256
    new_head_epoch
  }
  authority_checkpoint_ref?
  authority_checkpoint_sha256?
  authority_checkpoint_epoch?
  failure_code?
  committed_at?
  recorded_at
  signing_authority_binding      # Scope's mode-specific authority; see Contracts
  scope_signer_key_id
  scope_signer_key_epoch
  canonical_mutation_receipt_sha256
  signature
```

The anti-rollback anchor keeps one constant-size paired minimum outside the database's failure domain:

```text
(control_incarnation_id,
 authority_principal_id,
 authority_checkpoint_epoch/ref/hash,
 state_checkpoint_sequence/ref/hash)
```

Part of [Record reference](../record-reference.md).
