# Improvement proposals

> [!NOTE]
>
> **Design sketches.** Evidence, proposal, decision and release have separate meanings; the builders must simplify these unpublished bodies while preserving those meanings and their checks. Choosing their fields is implementation work. They become callable only after specification, schema publication and qualification. [Improvement and go-live](../improvement-and-go-live.md) explains Scope's optimizer; [Pale's SkillOpt path](../improvement-and-go-live.md#scope-instruction-improvement) owns instruction candidates and their release requirements.

```text
OptimizationCycleCheckpointV1
  schema_id
  schema_sha256
  cycle_checkpoint_id
  cycle_id
  cycle_stage                   snapshotted | candidate_generated |
                                evaluated | proposals_persisted | complete
  previous_cycle_checkpoint_ref?
  previous_cycle_checkpoint_sha256?
  input_snapshot_ref
  input_snapshot_root_sha256
  evaluation_policy_ref
  evaluation_policy_sha256
  stage_cursor
  candidate_set_root_sha256
  proposal_set_root_sha256
  persisted_record_ids[]
  stage_started_at
  stage_completed_at?
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_cycle_checkpoint_sha256
  signature

OptimizationProposalV1
  schema_id
  schema_sha256
  proposal_id
  cycle_id
  artifact_kind                 scoring_config | category_weight_map
  base_artifact_ref
  base_artifact_sha256
  base_artifact_version
  cycle_checkpoint_ref
  cycle_checkpoint_sha256
  input_snapshot_root_sha256
  edits[] {
    path
    prior_value_sha256
    proposed_value
  }
  edit_budget
  deterministic_edit_profile_ref
  deterministic_edit_profile_sha256
  candidate_artifact_schema_id
  candidate_artifact_schema_sha256
  candidate_artifact_ref
  candidate_artifact_sha256
  candidate_artifact_version
  evaluation_policy_ref
  evaluation_policy_sha256
  evaluation_method             observed_replay | bounded_sensitivity |
                                ips | mips
  logging_policy_version?
  propensity_evidence_ref?
  propensity_evidence_sha256?
  held_out_evidence_ref
  held_out_evidence_sha256
  candidate_evaluation_result_ref
  candidate_evaluation_result_sha256
  evaluation_pass
  holdout_delta
  rollback_anchor_ref
  rollback_anchor_sha256
  created_at
  proposer_principal_id
  proposer_key_id
  proposer_key_epoch
  canonical_proposal_sha256
  signature

OptimizationReleaseV1
  schema_id
  schema_sha256
  release_id
  proposal_schema_id
  proposal_schema_sha256
  proposal_ref
  proposal_sha256
  artifact_kind                 scoring_config | category_weight_map |
                                memory_item
  owner_ruling_ref               # illustrative; the ruling record is chosen later
  owner_ruling_sha256
  previous_release_ref?
  previous_release_sha256?
  expected_base_artifact_ref
  expected_base_artifact_sha256
  expected_base_artifact_version
  candidate_artifact_schema_id
  candidate_artifact_schema_sha256
  candidate_artifact_ref
  candidate_artifact_sha256
  candidate_artifact_version
  candidate_evaluation_result_ref
  candidate_evaluation_result_sha256
  released_artifact_ref
  released_artifact_sha256
  released_artifact_version
  owner_artifact_equivalence_ref?
  owner_artifact_equivalence_sha256?
  release_mode                   scope_native_atomic | owner_native_receipt
  owner_release_receipt_ref?
  owner_release_receipt_sha256?
  rollback_anchor_ref
  rollback_anchor_sha256
  applied_at
  release_authority_ref
  release_authority_sha256
  releaser_principal_id
  releaser_key_id
  releaser_key_epoch
  canonical_release_sha256
  signature

OwnerArtifactReleaseReceiptV1
  schema_id
  schema_sha256
  owner_release_receipt_id
  artifact_kind                  # defined by the releasing owner
  proposal_schema_id
  proposal_schema_sha256
  proposal_ref
  proposal_sha256
  owner_ruling_ref               # illustrative; the ruling record is chosen later
  owner_ruling_sha256
  expected_base_artifact_ref
  expected_base_artifact_sha256
  expected_base_artifact_version
  candidate_artifact_schema_id
  candidate_artifact_schema_sha256
  candidate_artifact_ref
  candidate_artifact_sha256
  candidate_artifact_version
  candidate_evaluation_result_ref
  candidate_evaluation_result_sha256
  released_artifact_ref
  released_artifact_sha256
  released_artifact_version
  owner_artifact_equivalence_ref?
  owner_artifact_equivalence_sha256?
  rollback_anchor_ref
  rollback_anchor_sha256
  owner_native_transaction_ref
  owner_native_transaction_sha256
  applied_at
  release_authority_ref
  release_authority_sha256
  owner_principal_id
  owner_key_id
  owner_key_epoch
  canonical_owner_release_receipt_sha256
  signature

OwnerArtifactEquivalenceV1
  schema_id
  schema_sha256
  equivalence_id
  artifact_kind
  candidate_artifact_schema_id
  candidate_artifact_schema_sha256
  candidate_artifact_ref
  candidate_artifact_sha256
  candidate_artifact_version
  released_artifact_schema_id
  released_artifact_schema_sha256
  released_artifact_ref
  released_artifact_sha256
  released_artifact_version
  deterministic_transformation_profile_ref
  deterministic_transformation_profile_sha256
  equivalence_proof_ref
  equivalence_proof_sha256
  accepted_equivalence_scope
  owner_principal_id
  owner_key_id
  owner_key_epoch
  canonical_owner_artifact_equivalence_sha256
  signature

EditLineageProjectionV1
  # Reckon owns this schema; Scope only produces signed instances.
```

```text
MemoryProposalV1
  schema_id
  schema_sha256
  proposal_id
  proposal_kind                 compact | merge | supersede | tombstone
  semantic_owner_ref
  base_artifact_set_ref
  base_artifact_set_sha256
  base_artifact_set_version
  cycle_checkpoint_ref
  cycle_checkpoint_sha256
  input_snapshot_root_sha256
  source_items[] {
    source_item_ref
    source_item_sha256
    source_item_version
  }
  proposed_item_schema_id
  proposed_item_schema_sha256
  proposed_item_ref
  proposed_item_sha256
  proposed_item_version
  derivation_policy_ref
  derivation_policy_sha256
  candidate_evaluation_result_ref
  candidate_evaluation_result_sha256
  model_or_rule_version
  confidence
  information_loss_report_ref
  information_loss_report_sha256
  authority_impact
  lifecycle_state               proposal
  reviewer_owner_ref
  created_at
  expires_at
  proposer_principal_id
  proposer_key_id
  proposer_key_epoch
  canonical_memory_proposal_sha256
  signature
```

Part of [Record reference](../record-reference.md).
