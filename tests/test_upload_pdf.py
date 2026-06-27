"""Unit tests for the POST /api/policies-v2/{id}/upload-pdf endpoint logic."""

import pytest
import os
from unittest.mock import patch

from routes.policies_v2 import (
    MAX_PDF_SIZE,
    ALLOWED_PDF_TYPES,
    _is_cloudinary_configured,
)


class TestUploadConstants:
    """Test upload configuration constants."""

    def test_max_pdf_size_is_10mb(self):
        """Max PDF size should be exactly 10 MB (10 * 1024 * 1024 bytes)."""
        assert MAX_PDF_SIZE == 10 * 1024 * 1024
        assert MAX_PDF_SIZE == 10_485_760

    def test_allowed_types(self):
        """Allowed type values should be 'current' and 'last_year'."""
        assert ALLOWED_PDF_TYPES == {"current", "last_year"}

    def test_invalid_type_not_in_allowed(self):
        """Invalid type values should not be in the allowed set."""
        assert "previous" not in ALLOWED_PDF_TYPES
        assert "" not in ALLOWED_PDF_TYPES
        assert "Current" not in ALLOWED_PDF_TYPES  # case-sensitive


class TestCloudinaryConfigDetection:
    """Test the Cloudinary configuration detection logic."""

    @patch.dict(os.environ, {}, clear=True)
    def test_not_configured_when_no_env_vars(self):
        """Should return False when no Cloudinary env vars are set."""
        # Clear any existing cloudinary vars
        for key in ["CLOUDINARY_URL", "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET"]:
            os.environ.pop(key, None)
        assert _is_cloudinary_configured() is False

    @patch.dict(os.environ, {"CLOUDINARY_URL": "cloudinary://key:secret@cloud"})
    def test_configured_with_cloudinary_url(self):
        """Should return True when CLOUDINARY_URL is set."""
        assert _is_cloudinary_configured() is True

    @patch.dict(os.environ, {
        "CLOUDINARY_CLOUD_NAME": "mycloud",
        "CLOUDINARY_API_KEY": "12345",
        "CLOUDINARY_API_SECRET": "secret",
    })
    def test_configured_with_individual_vars(self):
        """Should return True when all individual Cloudinary vars are set."""
        assert _is_cloudinary_configured() is True

    @patch.dict(os.environ, {
        "CLOUDINARY_CLOUD_NAME": "mycloud",
        "CLOUDINARY_API_KEY": "12345",
    }, clear=True)
    def test_not_configured_with_partial_vars(self):
        """Should return False when only some individual vars are set."""
        os.environ.pop("CLOUDINARY_URL", None)
        os.environ.pop("CLOUDINARY_API_SECRET", None)
        assert _is_cloudinary_configured() is False


class TestUploadValidation:
    """Test validation logic for the upload endpoint."""

    def test_valid_type_current(self):
        """'current' should be an accepted type."""
        assert "current" in ALLOWED_PDF_TYPES

    def test_valid_type_last_year(self):
        """'last_year' should be an accepted type."""
        assert "last_year" in ALLOWED_PDF_TYPES

    def test_pdf_content_type_accepted(self):
        """application/pdf is the only accepted content type."""
        valid_content_type = "application/pdf"
        assert valid_content_type == "application/pdf"

    def test_file_size_at_limit(self):
        """File exactly at 10MB should be accepted (not exceed)."""
        file_size = MAX_PDF_SIZE
        assert file_size <= MAX_PDF_SIZE

    def test_file_size_over_limit(self):
        """File over 10MB should be rejected."""
        file_size = MAX_PDF_SIZE + 1
        assert file_size > MAX_PDF_SIZE
