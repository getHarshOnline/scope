# Research exports

The request an admitted research requester signs and the minimised export Scope signs in return. The rules are on [Evidence export and Reckon](../evidence-export-and-reckon.md).

```text
ResearchEvidenceExportRequestV1
  schema_id
  schema_sha256
  request_id
  admission_binding             # exact standalone or Pale admission union
  research_owner_id
  experiment_manifest_ref
  experiment_manifest_sha256
  principal_scope
  controller_scope
  relationship_scope?
  purpose
  provenance_class              real_operational | synthetic_simulation
  adaptation_target_class?      context_memory | package_skill | normative_pack |
                                 model_profile | code_config | native_app_release
  permitted_use[]               recorded_source_runtime | context_retention |
                                 evaluation | calibration | training | fine_tuning |
                                 derivative_checkpoint_model | reusable_generalization |
                                 publication_disclosure
  evidence_classes[]
  question_classes[]
  pale_execution_evidence_selectors[] {
    execution_path_evidence {
      record_ref
      record_sha256
    }
    delegation_evidence[] {
      record_ref
      record_sha256
    }
    terminal_leaf_evidence? {
      record_ref
      record_sha256
    }
  }
  observed_time_range
  authority_evidence[] {
    authority_role              source_owner | data_controller | relationship |
                                 confidentiality | consent | rights |
                                 research_use | training_use | derivative_use |
                                 generalization_use | publication_use
    issuer_id
    schema_id
    schema_sha256
    record_ref
    record_sha256
  }
  minimization_policy_ref
  minimization_policy_sha256
  redaction_policy_ref
  redaction_policy_sha256
  retention_policy_ref
  retention_policy_sha256
  deletion_policy_ref
  deletion_policy_sha256
  dataset_split_policy_ref
  dataset_split_policy_sha256
  max_records
  max_bytes
  issued_at
  expires_at
  requester_principal_id
  requester_key_id
  requester_key_epoch
  canonical_request_sha256
  signature

ResearchEvidenceExportV1
  schema_id
  schema_sha256
  export_id
  request_ref
  request_sha256
  research_owner_id
  experiment_manifest_ref
  experiment_manifest_sha256
  principal_scope
  controller_scope
  relationship_scope?
  purpose
  provenance_class              exactly one request-selected class
  permitted_use[]
  source_frontiers[]             # owner/schema/ref/hash/revision or generation
  evidence_items[] {
    source_owner_id
    source_schema_id
    source_schema_sha256
    evidence_ref
    evidence_sha256
    evidence_class
    pale_execution_evidence? {
      execution_path_evidence {
        record_ref
        record_sha256
      }
      delegation_evidence[] {
        record_ref
        record_sha256
      }
      terminal_leaf_evidence? {
        record_ref
        record_sha256
      }
    }
    question_class?
    observed_at
    valid_through?
    bounded_derivation_ref?
    bounded_derivation_sha256?
  }
  omissions[]                    # requested-but-unavailable class and reason
  unknowns[]                     # never coerced to absent, false, or zero
  transform_profile_ref
  transform_profile_sha256
  dataset_split_id
  leakage_report_ref
  leakage_report_sha256
  selection_bias_report_ref
  selection_bias_report_sha256
  authority_evidence[]           # exact ordered subset validated from request
  retention_policy_ref
  retention_policy_sha256
  deletion_policy_ref
  deletion_policy_sha256
  expires_at
  record_count
  byte_count
  generated_at
  signing_authority_binding
  issuer_principal_id
  issuer_key_id
  issuer_key_epoch
  canonical_export_sha256
  signature
```

Part of [Record reference](../record-reference.md).
