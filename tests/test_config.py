import pytest

from retail_platform.config import load_settings, missing_required_environment


def test_missing_required_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("EVENTHUB_NAMESPACE", raising=False)
    monkeypatch.delenv("ADLS_ACCOUNT_NAME", raising=False)
    assert missing_required_environment() == ["EVENTHUB_NAMESPACE", "ADLS_ACCOUNT_NAME"]


def test_load_settings_from_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("EVENTHUB_NAMESPACE", "retail-dev")
    monkeypatch.setenv("ADLS_ACCOUNT_NAME", "retaillake")
    settings = load_settings()
    assert settings.eventhub_namespace == "retail-dev"
    assert settings.bronze_filesystem == "bronze"
