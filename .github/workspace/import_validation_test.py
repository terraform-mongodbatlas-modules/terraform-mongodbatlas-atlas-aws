# path-sync copy -n sdlc
from __future__ import annotations

import pytest

from workspace import models
from workspace.import_validation import (
    SKIP_SENTINEL,
    assert_import_plan,
    extract_import_id,
    extract_state_resources,
    generate_import_blocks_tf,
    validate_atlas_types,
)

MAPPING = {
    "mongodbatlas_encryption_at_rest": "{project_id}",
    "mongodbatlas_cloud_provider_access_setup": "{project_id}-{role_id}-AWS",
    "mongodbatlas_privatelink_endpoint": "{project_id}-{private_link_id}-AWS-{region}",
    "mongodbatlas_log_integration": SKIP_SENTINEL,
}


def test_extract_import_id_atlas_type():
    attrs = {"project_id": "p1", "role_id": "r1"}
    result = extract_import_id("mongodbatlas_cloud_provider_access_setup", attrs, MAPPING)
    assert result == "p1-r1-AWS"


def test_extract_import_id_non_atlas():
    assert extract_import_id("aws_kms_key", {"id": "123"}, MAPPING) is None


def test_extract_import_id_skip():
    assert extract_import_id("mongodbatlas_log_integration", {}, MAPPING) is None


def test_validate_atlas_types_missing():
    with pytest.raises(ValueError, match="mongodbatlas_new_resource"):
        validate_atlas_types({"mongodbatlas_new_resource"}, MAPPING)


def test_validate_atlas_types_ok():
    validate_atlas_types({"mongodbatlas_encryption_at_rest"}, MAPPING)


def test_generate_import_blocks_tf():
    entries = [
        ("module.ex_enc.mongodbatlas_encryption_at_rest.this", "proj-123"),
        ("module.ex_enc.mongodbatlas_cloud_provider_access_setup.this", "proj-123-role-1-AWS"),
    ]
    result = generate_import_blocks_tf(entries)
    assert "to = module.ex_enc.mongodbatlas_encryption_at_rest.this" in result
    assert 'id = "proj-123"' in result
    assert 'id = "proj-123-role-1-AWS"' in result
    assert result.count("import {") == 2


def test_extract_state_resources():
    state = {
        "values": {
            "root_module": {
                "resources": [
                    {"address": "aws_kms_key.this", "type": "aws_kms_key", "values": {"id": "k1"}},
                ],
                "child_modules": [
                    {
                        "resources": [
                            {
                                "address": "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                                "type": "mongodbatlas_encryption_at_rest",
                                "values": {"project_id": "p1"},
                            }
                        ],
                        "child_modules": [],
                    }
                ],
            }
        }
    }
    resources = extract_state_resources(state)
    assert "aws_kms_key.this" in resources
    assert (
        resources["module.ex_enc.mongodbatlas_encryption_at_rest.this"].resource_type
        == "mongodbatlas_encryption_at_rest"
    )


def _make_rc(
    address: str,
    actions: list[str],
    importing: bool = False,
    before: dict | None = None,
    after: dict | None = None,
) -> dict:
    rc: dict = {
        "address": address,
        "change": {"actions": actions, "before": before or {}, "after": after or {}},
    }
    if importing:
        rc["importing"] = {"id": "some-id"}
    return rc


def _make_example(
    name: str, known_changes: list[models.ImportKnownChange] | None = None
) -> models.Example:
    return models.Example(
        name=name,
        import_validation=models.ImportValidationConfig(
            enabled=True,
            known_changes=known_changes or [],
        ),
    )


def test_assert_import_plan_clean():
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this", ["no-op"], importing=True
            ),
        ]
    }
    assert assert_import_plan(plan_json, _make_example("enc")) == []


def test_assert_import_plan_unexpected_create():
    plan_json = {
        "resource_changes": [
            _make_rc("module.ex_enc.mongodbatlas_encryption_at_rest.this", ["create"]),
        ]
    }
    failures = assert_import_plan(plan_json, _make_example("enc"))
    assert len(failures) == 1
    assert "unexpected actions" in failures[0]


def test_assert_import_plan_known_change():
    kc = models.ImportKnownChange(
        address="mongodbatlas_encryption_at_rest.this",
        actions=["update"],
        changed_attributes=["project_id"],
    )
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                ["update"],
                importing=True,
                before={"project_id": "old"},
                after={"project_id": "new"},
            ),
        ]
    }
    assert assert_import_plan(plan_json, _make_example("enc", [kc])) == []


def test_assert_import_plan_attribute_mismatch():
    kc = models.ImportKnownChange(
        address="mongodbatlas_encryption_at_rest.this",
        actions=["update"],
        changed_attributes=["project_id"],
    )
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                ["update"],
                importing=True,
                before={"project_id": "old", "name": "a"},
                after={"project_id": "new", "name": "b"},
            ),
        ]
    }
    failures = assert_import_plan(plan_json, _make_example("enc", [kc]))
    assert len(failures) == 1
    assert "expected changed_attributes" in failures[0]


def test_assert_import_plan_wildcard_known_change():
    kc = models.ImportKnownChange(
        address="mongodbatlas_encryption_at_rest.this",
        actions=["update"],
        changed_attributes=[],
    )
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                ["update"],
                importing=True,
                before={"project_id": "old", "name": "a"},
                after={"project_id": "new", "name": "b"},
            ),
        ]
    }
    assert assert_import_plan(plan_json, _make_example("enc", [kc])) == []


def test_assert_import_plan_non_importing_update():
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                ["update"],
                importing=False,
            ),
        ]
    }
    failures = assert_import_plan(plan_json, _make_example("enc"))
    assert len(failures) == 1
    assert "non-import change" in failures[0]


def test_assert_import_plan_actions_mismatch():
    kc = models.ImportKnownChange(
        address="mongodbatlas_encryption_at_rest.this",
        actions=["no-op"],
        changed_attributes=[],
    )
    plan_json = {
        "resource_changes": [
            _make_rc(
                "module.ex_enc.mongodbatlas_encryption_at_rest.this",
                ["update"],
                importing=True,
                before={"project_id": "old"},
                after={"project_id": "new"},
            ),
        ]
    }
    failures = assert_import_plan(plan_json, _make_example("enc", [kc]))
    assert len(failures) == 1
    assert "expected actions" in failures[0]


def test_extract_import_id_missing_attribute():
    with pytest.raises(KeyError, match="mongodbatlas_encryption_at_rest.*missing_attr"):
        extract_import_id(
            "mongodbatlas_encryption_at_rest",
            {"other_field": "val"},
            {"mongodbatlas_encryption_at_rest": "{missing_attr}"},
        )
