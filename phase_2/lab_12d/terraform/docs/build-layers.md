# Manual Lambda Layer Build

These steps manually build the Lab 12d ReportLab Lambda layer from a clean
Terraform working directory.

This layer is used by:

- `aws_lambda_function.executive_dashboard`
- `aws_lambda_function.compliance_agent`

## Prerequisites

- Python 3.12 available as `python3`
- Active Python virtual environment
- `pip`, `setuptools`, and `wheel` upgraded in that environment
- Lab dependencies installed from the lab `requirements.txt`
- Terraform commands run from this lab's `terraform/` directory

References:

- AWS Lambda Python layers: <https://docs.aws.amazon.com/lambda/latest/dg/python-layers.html>
- AWS layer package paths: <https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html>
- pip install options: <https://pip.pypa.io/en/stable/cli/pip_install/>

## Expected Clean Start

Start from the Lab 12d root directory. This is the directory that contains
`requirements.txt` and `terraform/`.

The normal manual workflow assumes this layer path does not already exist:

```text
terraform/lambda/layers/reportlab-layer
```

If that directory already exists, decide whether you want to preserve it or
intentionally rebuild it. The automated script supports intentional rebuilds with
`--force`.

## Prepare Python

```bash
python3 -m venv .
source bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

The virtual environment prepares local tooling. The Lambda layer itself is built
with a separate `pip install --target` command so dependencies are copied into
the exact directory shape Lambda expects.

## Create The Layer Directory

```bash
cd terraform

LAYER_DIR="lambda/layers/reportlab-layer"
SITE_PACKAGES="$LAYER_DIR/python/lib/python3.12/site-packages"

test ! -e "$LAYER_DIR"
mkdir -p "$SITE_PACKAGES"
```

The `test ! -e "$LAYER_DIR"` check protects existing layer content during a
manual build. If it fails, stop and decide whether to use the automated rebuild
path instead.

## Install Lambda-Compatible Packages

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

The `--platform manylinux2014_x86_64` option targets Linux-compatible package
files for the Lambda runtime rather than the local workstation operating system.

Keep `boto3/docs` and `botocore/docs` in the layer. Removing them can cause
Lambda startup errors such as:

```text
No module named 'boto3.docs'
```

## Verify The Layer

```bash
test -d "$SITE_PACKAGES/reportlab"
test -d "$SITE_PACKAGES/boto3/docs"
test -d "$SITE_PACKAGES/botocore/docs"

touch "$SITE_PACKAGES/boto3/docs/__init__.py"
touch "$SITE_PACKAGES/botocore/docs/__init__.py"
```

Expected path shape:

```text
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/reportlab/
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/boto3/docs/
lambda/layers/reportlab-layer/python/lib/python3.12/site-packages/botocore/docs/
```

## Deploy With Terraform

Terraform packages the layer from this directory:

```hcl
source_dir = "${path.module}/lambda/layers/reportlab-layer"
```

Keep `source_dir` pointed at `reportlab-layer`, not the inner `python/`
directory. Lambda expects the ZIP file to contain `python/` at the top level.

```bash
terraform fmt -check -recursive
terraform plan
terraform apply
```

## Script Equivalent

From this lab's `terraform/` directory:

```bash
./scripts/build-layers.sh
terraform apply
```

If an existing layer is invalid and you intentionally want to replace it:

```bash
./scripts/build-layers.sh --force
terraform apply
```
