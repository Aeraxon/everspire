#!/usr/bin/env python3
"""
Preload all marker models during Docker build.
This ensures the first API request doesn't have to wait for model downloads.
"""

import sys
print("=" * 60)
print("Preloading Marker Models...")
print("=" * 60)

try:
    # Import marker to trigger model downloads
    from marker.converters.pdf import PdfConverter
    from marker.models import create_model_dict

    print("\n[1/2] Creating model dictionary...")
    # This downloads and initializes all required models:
    # - Surya OCR
    # - Surya Layout Detection
    # - Surya Reading Order
    # - Surya Table Recognition
    model_dict = create_model_dict()

    print(f"[2/2] Models loaded successfully!")
    print(f"      Loaded {len(model_dict)} model components")

    # List loaded models
    for name, model in model_dict.items():
        model_type = type(model).__name__
        print(f"      - {name}: {model_type}")

    print("\n" + "=" * 60)
    print("Model preloading complete!")
    print("=" * 60)

except Exception as e:
    print(f"\nError preloading models: {e}", file=sys.stderr)
    print("Models will be downloaded on first request.", file=sys.stderr)
    # Don't fail the build, just warn
    sys.exit(0)
