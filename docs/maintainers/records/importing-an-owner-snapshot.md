# Importing an owner snapshot

The owner's delegation, the import admission, the deployment's import profile, the adapter's staging manifest, the import body, Scope's import receipt and the audit-anchor receipt, followed by the two shapes a staged chunk may contain. The rules are on [Source imports](../source-imports.md).

```text
SourceSnapshotImportDelegationV1
  schema_id
  schema_sha256
  delegation_id
  authority_reference
  authority_reference_sha256
  resource_owner_principal_id
  delegate_principal_id
  delegate_role                  delegated_adapter | pale_admission
  permitted_source_owner
  permitted_source_namespaces[]
  principal_scope
  controller_scope
  relationship_scope?
  permitted_purposes[]
  issued_at
  expires_at
  non_transitive                # always true
  issuer_key_id
  issuer_key_epoch
  canonical_delegation_sha256
  signature
```

```text
SourceSnapshotImportAdmissionV1
  schema_id
  schema_sha256
  request_id
  caller_identity
  authority_reference
  authority_reference_sha256
  resource_owner_principal_id
  resource_owner_trust_record_ref?
  resource_owner_trust_record_sha256?
  checked_scope_authority_checkpoint_ref?
  checked_scope_authority_checkpoint_sha256?
  issuer_role                   resource_owner | delegated_adapter |
                                pale_admission
  issuer_principal_id
  issuer_delegation_ref?
  issuer_delegation_sha256?
  issuer_deployment_binding_ref?
  issuer_deployment_binding_sha256?
  issuer_session_grant_ref?
  issuer_session_grant_sha256?
  issuer_common_request_ref?
  issuer_common_request_sha256?
  permitted_source_owner
  permitted_source_namespaces[]
  principal_scope
  controller_scope
  relationship_scope?
  purpose
  import_body_sha256
  issued_at
  expires_at
  canonical_admission_sha256
  issuer_key_id
  issuer_key_epoch
  signature
```

```text
SourceSnapshotImportProfileV1
  schema_id
  schema_sha256
  profile_id
  profile_version
  profile_epoch
  previous_profile_ref?
  previous_profile_sha256?
  state                        active | retired
  scope_instance_id
  deployment_mode              standalone | pale_integrated
  principal_scope
  controller_scope
  relationship_scope?
  deployment_binding_ref?      # required only for pale_integrated
  deployment_binding_sha256?
  authority_checkpoint_ref
  authority_checkpoint_sha256
  authority_checkpoint_epoch
  max_chunks
  max_records_per_chunk
  max_chunk_uncompressed_bytes
  max_manifest_bytes
  max_total_items
  max_total_tombstones
  max_total_payload_bytes
  max_inline_payload_bytes
  max_staging_age_seconds
  max_validation_wall_time_ms
  max_activation_transaction_ms
  max_concurrent_staging_sessions_per_namespace
  max_concurrent_staging_sessions_per_instance
  target_activation_p95_ms
  target_activation_p99_ms
  content_store_profile_ref
  content_store_profile_sha256
  issued_at
  expires_at
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_import_profile_sha256
  signature
```

```text
SourceSnapshotStagingManifestV1
  schema_id
  schema_sha256
  staging_manifest_id
  source_owner
  source_namespace
  principal_scope
  controller_scope
  relationship_scope?
  mode                         full | delta
  requested_generation
  expected_previous_generation?
  import_profile_ref
  import_profile_sha256
  checked_import_profile_head_ref
  checked_import_profile_head_sha256
  checked_import_profile_head_epoch
  adapter_principal_id
  adapter_instance_id
  adapter_version
  adapter_binding_ref
  adapter_binding_sha256
  acquisition_receipt_ref
  acquisition_receipt_sha256
  chunks[] {
    chunk_index
    chunk_kind                 items | tombstones
    first_source_record_ref
    last_source_record_ref
    record_count
    uncompressed_bytes
    chunk_schema_id
    chunk_schema_sha256
    chunk_content_ref
    chunk_content_sha256
  }
  declared_item_count
  declared_tombstone_count
  declared_payload_bytes
  observed_at
  valid_through
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_staging_manifest_sha256
  signature
```

```text
SourceSnapshotImportV1
  schema_id
  schema_sha256
  import_id
  source_owner
  source_namespace
  principal_scope
  controller_scope
  relationship_scope?
  mode                         full | delta
  complete_set_policy_ref?
  complete_set_policy_sha256?
  complete_set_policy_head_ref?
  complete_set_policy_head_sha256?
  complete_set_policy_head_epoch?
  requested_generation
  expected_previous_generation?
  import_profile_ref
  import_profile_sha256
  checked_import_profile_head_ref
  checked_import_profile_head_sha256
  checked_import_profile_head_epoch
  staging_manifest_ref
  staging_manifest_sha256
  source_snapshot_digest
  manifest_digest
  declared_chunk_count
  declared_item_count
  declared_tombstone_count
  declared_payload_bytes
  observed_at
  valid_through
```

```text
SourceSnapshotImportReceiptV1
  schema_id
  schema_sha256
  receipt_id
  import_id
  import_body_sha256
  admission_request_id
  admission_ref
  admission_sha256
  delegation_ref?
  delegation_sha256?
  scope_authority_frontier?      # ScopeAuthorityFrontierV1; import_delegation only
  deployment_binding_ref?
  deployment_binding_sha256?
  session_grant_ref?
  session_grant_sha256?
  common_request_ref?
  common_request_sha256?
  federation_request_admission_ref?
  federation_request_admission_sha256?
  source_owner
  source_namespace
  principal_scope
  controller_scope
  relationship_scope?
  requested_generation
  previous_generation?
  committed_generation?
  source_snapshot_digest
  manifest_digest
  complete_set_policy_ref?
  complete_set_policy_sha256?
  checked_complete_set_policy_head_ref?
  checked_complete_set_policy_head_sha256?
  checked_complete_set_policy_head_epoch?
  import_profile_ref
  import_profile_sha256
  checked_import_profile_head_ref
  checked_import_profile_head_sha256
  checked_import_profile_head_epoch
  staging_manifest_ref
  staging_manifest_sha256
  declared_chunk_count
  declared_payload_bytes
  accepted_item_count
  accepted_tombstone_count
  disposition                   committed | duplicate | conflict | rejected
  disposition_reason?
  duplicate_of_receipt_ref?
  duplicate_of_receipt_sha256?
  duplicate_of_audit_anchor_receipt_ref?
  duplicate_of_audit_anchor_receipt_sha256?
  committed_at?
  recorded_at
  canonical_receipt_sha256
  signing_authority_binding      # Scope's mode-specific authority; see Contracts
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  signature
```

```text
ScopeSourceImportAuditAnchorReceiptV1
  schema_id
  schema_sha256
  anchor_receipt_id
  import_receipt_ref
  import_receipt_sha256
  source_owner
  source_namespace
  principal_scope
  controller_scope
  relationship_scope?
  generation?
  semantic_state_transaction_id
  semantic_state_root_sha256
  dolt_commit_ref
  dolt_commit_sha256
  journal_terminal_state
  anchored_at
  canonical_audit_anchor_receipt_sha256
  signing_authority_binding      # Scope's mode-specific authority; see Contracts
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  signature
```

```text
item {
  source_record_ref
  source_version
  record_schema_id
  record_schema_sha256
  content_digest
  inline_payload?              # exactly one representation
  immutable_content_ref?
  classification
  authority_class
  lifecycle_state
  provenance_evidence[] {
    provenance_ref
    provenance_sha256
  }
  observed_at
  valid_through
}

tombstone {
  source_record_ref
  source_version
  tombstone_kind               explicit | policy_omission
  deletion_or_absence_reason
  authority_reference
  authority_reference_sha256
  complete_set_policy_ref?
  complete_set_policy_sha256?
  first_absent_generation?
  current_absent_generation?
  absence_evidence_ref?
  absence_evidence_sha256?
  grace_evidence_ref?
  grace_evidence_sha256?
  reconciliation_evidence_ref?
  reconciliation_evidence_sha256?
  observed_at
}
```

Part of [Record reference](../record-reference.md).
