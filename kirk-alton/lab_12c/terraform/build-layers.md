# Manual Lambda Layer Build

These steps manually recreate what `scripts/build_layers.sh` does for the Lab
12c ReportLab layer.

This layer is used by:

- `aws_lambda_function.executive_dashboard`
- `aws_lambda_function.compliance_agent`

## What The Layer Does

The reporting Lambdas import `reportlab` to create PDF reports. `reportlab` is
not built into the AWS Lambda Python runtime, so we put it in a Lambda layer.

When Lambda starts, it mounts layers under `/opt`. For Python layers, Lambda
knows how to import packages from paths like:

```text
/opt/python/lib/python3.12/site-packages
```

That is why this repo builds the layer here:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages
```

Terraform zips `lambda/layers/reportlab-layer`, so the ZIP root contains the
required `python/` directory.

References:

- AWS Python layers: <https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html>
- AWS layer paths by runtime: <https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html>
- AWS Python import path behavior: <https://docs.aws.amazon.com/lambda/latest/dg/python-package.html#python-package-dependencies>

## Install For Lambda

The packages must be installed for Lambda's operating system, not your laptop's
operating system. Lambda runs on Amazon Linux, so the pip install command targets
Linux-compatible package files:

```text
--platform manylinux2014_x86_64
```

That is the important part when building this layer from macOS.

References:

- Python package formats: <https://packaging.python.org/en/latest/discussions/package-formats/>
- Python platform compatibility tags: <https://packaging.python.org/en/latest/specifications/platform-compatibility-tags/>
- pip install options: <https://pip.pypa.io/en/stable/cli/pip_install/>

## Build Target

- Runtime: `python3.12`
- Architecture: `x86_64`
- Linux package target: `manylinux2014_x86_64`
- Layer directory: `lambda/layers/reportlab-layer`
- Package directory: `python/lib/python3.12/site-packages`

Packages installed:

- `reportlab==4.4.3`
- `boto3>=1.34`
- `botocore>=1.34`

Keep `boto3/docs` and `botocore/docs`. Removing them can cause Lambda startup
errors like:

```text
No module named 'boto3.docs'
```

## Build The Layer

Run from the Lab 12c Terraform directory:

```bash
cd /Users/kirk/devsecops/class-7-tko-group-armageddon-2/kirk-alton/lab_12c/terraform
source .venv/bin/activate
```

Create a clean layer folder:

```bash
LAYER_DIR="lambda/layers/reportlab-layer"
SITE_PACKAGES="$LAYER_DIR/python/lib/python3.12/site-packages"

rm -rf "$LAYER_DIR"
mkdir -p "$SITE_PACKAGES"
```

Install the packages for Lambda:

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

Clean extra files while keeping required boto3/botocore docs:

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

Check that the important packages are still there:

```bash
test -d "$SITE_PACKAGES/reportlab"
test -d "$SITE_PACKAGES/boto3/docs"
test -d "$SITE_PACKAGES/botocore/docs"

touch "$SITE_PACKAGES/boto3/docs/__init__.py"
touch "$SITE_PACKAGES/botocore/docs/__init__.py"
```

## Deploy With Terraform

Terraform packages the layer with this block in `50-lambda.tf`:

```hcl
source_dir = "${path.module}/lambda/layers/reportlab-layer"
```

Keep `source_dir` pointed at `reportlab-layer`, not the inner `python`
directory. Lambda expects the ZIP to contain `python/` at the top level.

```bash
terraform fmt -check 50-lambda.tf
terraform plan
terraform apply
```

Confirm the ZIP layout:

```bash
unzip -l lambda/layers/reportlab-layer.zip \
  | grep -E 'python/lib/python3.12/site-packages/(reportlab|boto3/docs|botocore/docs)' \
  | head
```

Expected path shape:

```text
python/lib/python3.12/site-packages/reportlab/
python/lib/python3.12/site-packages/boto3/docs/
python/lib/python3.12/site-packages/botocore/docs/
```

## Script Equivalent

```bash
./scripts/build_layers.sh --force
terraform apply
```

Use `--force` when rebuilding after dependency changes or repairing a broken
layer.
