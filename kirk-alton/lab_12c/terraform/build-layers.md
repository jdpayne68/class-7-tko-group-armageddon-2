# Manual Lambda Layer Build

This runbook manually recreates what `scripts/build_layers.sh` does for the
Executive Dashboard Lambda ReportLab layer.

## Purpose

The Executive Dashboard Lambda imports `reportlab` at startup. ReportLab is not
included in the standard Lambda Python runtime, so the function needs a Lambda
layer containing:

- `reportlab==4.4.3`
- `boto3>=1.34`
- `botocore>=1.34`
- package-internal `boto3/docs`
- package-internal `botocore/docs`

The `boto3/docs` and `botocore/docs` directories must be preserved. They are
used by boto3/botocore internals and removing them can cause Lambda import
errors such as:

```text
No module named 'boto3.docs'
No module named 'botocore.docs'
```

## Required Layer Shape

Terraform archives this directory:

```text
lambda/layers/reportlab-layer
```

The layer content must therefore live under:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages
```

When attached to Lambda, AWS mounts the layer under `/opt`, and Python can load:

```text
/opt/python/lib/python3.12/site-packages
```

Do not archive only the inner `python` directory. The ZIP must contain
`python/...` at the ZIP root.

## Manual Build

Run from the Terraform directory:

```bash
cd /Users/kirk/devsecops/class-7-tko-group-armageddon-2/kirk-alton/lab_12c/terraform
```

Activate the project virtual environment:

```bash
source .venv/bin/activate
```

Set the layer paths:

```bash
LAYER_DIR="lambda/layers/reportlab-layer"
SITE_PACKAGES="$LAYER_DIR/python/lib/python3.12/site-packages"
```

Remove the old layer contents:

```bash
rm -rf "$LAYER_DIR"
mkdir -p "$SITE_PACKAGES"
```

Install Lambda-compatible Linux wheels into the layer:

```bash
python3 -m pip install \
  --upgrade \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all: \
  --target "$SITE_PACKAGES" \
  'boto3>=1.34' \
  'botocore>=1.34' \
  'reportlab==4.4.3'
```

Clean obvious local/runtime noise while preserving boto3 and botocore docs:

```bash
find "$LAYER_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$LAYER_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true
find "$LAYER_DIR" -type f -name ".DS_Store" -delete 2>/dev/null || true
find "$LAYER_DIR" -type d -name "test" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
find "$LAYER_DIR" -type d -name "tests" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
find "$LAYER_DIR" -type d -name "docs" \
  -not -path "*/boto3/docs*" \
  -not -path "*/boto3/*" \
  -not -path "*/botocore/docs*" \
  -not -path "*/botocore/*" \
  -exec rm -rf {} + 2>/dev/null || true
find "$LAYER_DIR" -type d -name "examples" -not -path "*/botocore/*" -exec rm -rf {} + 2>/dev/null || true
```

Ensure package doc modules remain importable:

```bash
test -d "$SITE_PACKAGES/reportlab"
test -d "$SITE_PACKAGES/boto3"
test -d "$SITE_PACKAGES/boto3/docs"
test -d "$SITE_PACKAGES/botocore/docs"
```

Add missing package markers if needed:

```bash
touch "$SITE_PACKAGES/boto3/docs/__init__.py"
touch "$SITE_PACKAGES/botocore/docs/__init__.py"
```

## Verify Locally

Check the expected directories:

```bash
find "$SITE_PACKAGES" -maxdepth 2 -type d \
  \( -name reportlab -o -name boto3 -o -name docs -o -name botocore \) \
  | sort
```

Confirm required modules are present:

```bash
test -d "$SITE_PACKAGES/reportlab" && echo "reportlab present"
test -d "$SITE_PACKAGES/boto3/docs" && echo "boto3.docs present"
test -d "$SITE_PACKAGES/botocore/docs" && echo "botocore.docs present"
```

Optional local import check:

```bash
PYTHONPATH="$SITE_PACKAGES" python3 - <<'PY'
import reportlab
import boto3
import boto3.docs
import botocore.docs

print("All required imports are present")
PY
```

This import check can fail on macOS if Linux-only wheels were installed. If the
directory checks pass and the install command used `manylinux2014_x86_64`, the
layer structure is still appropriate for the x86_64 Lambda runtime.

## Verify Terraform Packaging

The active Terraform layer packaging lives in:

```text
09-lambda.tf
```

The important part is:

```hcl
data "archive_file" "reportlab_layer" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/layers/reportlab-layer"
  output_path = "${path.module}/lambda/layers/reportlab-layer.zip"
}
```

That `source_dir` should remain the layer root, not the inner `python`
directory.

Run formatting before deployment:

```bash
terraform fmt -check -diff
```

Build the layer ZIP and deploy through Terraform:

```bash
terraform plan
terraform apply
```

After Terraform creates `lambda/layers/reportlab-layer.zip`, confirm the ZIP has
the correct root path:

```bash
unzip -l lambda/layers/reportlab-layer.zip | grep -E 'python/lib/python3.12/site-packages/(reportlab|boto3/docs|botocore/docs)' | head
```

Expected matches include paths like:

```text
python/lib/python3.12/site-packages/reportlab/
python/lib/python3.12/site-packages/boto3/docs/
python/lib/python3.12/site-packages/botocore/docs/
```

## Fast Script Equivalent

The supported script path is:

```bash
./scripts/build_layers.sh --force
terraform apply
```

Use `--force` when recovering from a broken or stripped layer. Without
`--force`, the script may reuse an existing layer only if `reportlab`,
`boto3/docs`, and `botocore/docs` are already present.

## Troubleshooting

If Lambda reports:

```text
No module named 'reportlab'
```

Check that `reportlab` exists under:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/reportlab
```

If Lambda reports:

```text
No module named 'boto3.docs'
```

Check that cleanup did not remove:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/boto3/docs
```

If Lambda reports:

```text
No module named 'botocore.docs'
```

Check that cleanup did not remove:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/botocore/docs
```

If imports work locally but Lambda still fails, confirm:

- the layer was rebuilt with `--force` or the manual clean install steps
- `terraform apply` created a new `aws_lambda_layer_version`
- the Executive Dashboard Lambda references the latest ReportLab layer ARN
- the Lambda architecture is `x86_64`
- packages were installed with `--platform manylinux2014_x86_64`
