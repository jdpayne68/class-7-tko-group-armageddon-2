#!/usr/bin/env python3
# impostor_syndrome_defense.py

import random
import time
import subprocess
import sys
import os
import re

# ============================================
# DEFINE ALL CONSTANTS FIRST
# ============================================

skills = [
    "Lambda",
    "IAM",
    "Terraform",
    "API Gateway",
    "WAF",
    "CloudWatch",
    "DynamoDB",
    "EventBridge",
    "Bedrock",
    "Cognito",
    "RBAC",
]

truths = [
    "You are not behind. You are building.",
    "Confusion is not failure. Confusion is the start of learning.",
    "Errors are not insults. They are instructions.",
    "CloudWatch is not judging you. It is helping you.",
    "Terraform errors look scary because Terraform has no bedside manner.",
    "IAM denied you because IAM is doing its job.",
    "If you debugged it, you learned it.",
    "If you broke it and fixed it, you own it.",
    "You are allowed to be new and still be serious.",
    "You do not need to know everything. You need to know how to investigate.",
]

warnings = [
    "Do not compare your chapter 2 to someone else's chapter 20.",
    "Do not let one failed apply define your engineering future.",
    "Do not confuse discomfort with incompetence.",
    "Do not outsource your thinking to AI.",
    "Do not panic. Read the logs.",
]


# ============================================
# HELPER FUNCTIONS
# ============================================

def print_slow(text, delay=0.03):
    """Print text character by character for dramatic effect."""
    for char in text:
        print(char, end="", flush=True)
        time.sleep(delay)
    print()


def get_terraform_variables(tf_dir="."):
    """
    Parse Terraform configuration to find required variables and prompt user for them.

    Returns:
        dict: Dictionary of variable names and their values
    """
    variables = {}

    print("\n📋 Checking for required Terraform variables...")
    print("=" * 50)

    # Check if variables.tf exists
    var_tf_path = os.path.join(tf_dir, 'variables.tf')
    if not os.path.exists(var_tf_path):
        print("ℹ️  No variables.tf found. Using defaults.")
        return variables

    # Parse variables.tf for variable declarations
    with open(var_tf_path, 'r') as f:
        content = f.read()

    # Find all variable declarations
    var_pattern = r'variable\s+"([^"]+)"\s*{[^}]*?description\s*=\s*"([^"]*)"'
    matches = re.findall(var_pattern, content, re.DOTALL)

    for var_name, description in matches:
        # Check if variable has default value
        default_pattern = rf'default\s*=\s*([^\n]+)'
        default_match = re.search(default_pattern, content[content.index(f'variable "{var_name}"'):], re.DOTALL)

        # Check if variable is required (no default)
        if not default_match or 'null' in default_match.group(1):
            print(f"\n🔑 Variable: {var_name}")
            if description:
                print(f"   Description: {description}")

            # Try to guess sensible defaults based on variable name
            suggested = None
            if 'region' in var_name.lower():
                suggested = 'us-east-1'
            elif 'environment' in var_name.lower() or 'env' in var_name.lower():
                suggested = 'dev'
            elif 'project' in var_name.lower():
                suggested = 'my-project'
            elif 'access_key' in var_name.lower() or 'secret_key' in var_name.lower():
                suggested = os.environ.get('AWS_ACCESS_KEY_ID', '')

            if suggested:
                print(f"   Suggested: {suggested}")

            value = input(f"   Enter value: ").strip()
            if not value and suggested:
                value = suggested

            if value:  # Only add if user provided a value
                variables[var_name] = value

    return variables


def run_terraform_plan_only(tf_dir="."):
    """
    Run terraform plan with interactive variable prompts, but don't apply.

    Returns:
        tuple: (success: bool, output: str, error: str)
    """
    print("\n📋 Running terraform plan only (no apply)...")
    print("=" * 50)

    # Check terraform installation
    try:
        subprocess.run(["terraform", "version"],
                       capture_output=True,
                       check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Terraform not found. Please install Terraform first.")
        return False, "", "Terraform not installed"

    original_dir = os.getcwd()
    try:
        os.chdir(tf_dir)
    except FileNotFoundError:
        print(f"❌ Directory '{tf_dir}' not found.")
        return False, "", f"Directory '{tf_dir}' not found"

    # Get variables
    variables = get_terraform_variables(tf_dir)

    # Build command
    cmd = ["terraform", "plan"]
    for var_name, var_value in variables.items():
        cmd.extend(["-var", f"{var_name}={var_value}"])

    print("\n📋 Running terraform plan...")
    print("   Command:", " ".join(cmd))
    print("-" * 50)

    # Run plan interactively
    process = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    stdout_parts = []
    stderr_parts = []

    # Read stdout in real-time
    while True:
        line = process.stdout.readline()
        if not line:
            break
        print(line, end='')
        stdout_parts.append(line)

    # Read stderr
    for line in process.stderr:
        print(line, end='', file=sys.stderr)
        stderr_parts.append(line)

    process.wait()
    os.chdir(original_dir)

    if process.returncode == 0:
        print("\n✅ Terraform plan completed successfully!")
        return True, ''.join(stdout_parts), ''.join(stderr_parts)
    else:
        print("\n❌ Terraform plan failed!")
        return False, ''.join(stdout_parts), ''.join(stderr_parts)


def run_terraform_apply(tf_dir=".", auto_approve=False):
    """
    Run terraform apply with interactive variable prompts.

    Args:
        tf_dir: Directory containing Terraform files
        auto_approve: Whether to auto-approve the apply

    Returns:
        tuple: (success: bool, output: str, error: str)
    """
    print("\n🚀 Running Terraform apply...")
    print("=" * 50)

    # Check terraform installation
    try:
        subprocess.run(["terraform", "version"],
                       capture_output=True,
                       check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Terraform not found. Please install Terraform first.")
        return False, "", "Terraform not installed"

    original_dir = os.getcwd()
    try:
        os.chdir(tf_dir)
    except FileNotFoundError:
        print(f"❌ Directory '{tf_dir}' not found.")
        return False, "", f"Directory '{tf_dir}' not found"

    # First run terraform init
    print("\n📦 Initializing Terraform...")
    init_result = subprocess.run(
        ["terraform", "init"],
        capture_output=True,
        text=True
    )

    if init_result.returncode != 0:
        print("❌ Terraform init failed!")
        print(init_result.stderr)
        os.chdir(original_dir)
        return False, init_result.stdout, init_result.stderr

    print("✅ Terraform init successful")

    # Get variables
    variables = get_terraform_variables(tf_dir)

    # First run plan to show changes
    cmd_plan = ["terraform", "plan"]
    for var_name, var_value in variables.items():
        cmd_plan.extend(["-var", f"{var_name}={var_value}"])

    print("\n📋 Running terraform plan...")
    print("   Command:", " ".join(cmd_plan))
    print("-" * 50)

    plan_process = subprocess.Popen(
        cmd_plan,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Display plan output in real-time
    while True:
        line = plan_process.stdout.readline()
        if not line:
            break
        print(line, end='')

    for line in plan_process.stderr:
        print(line, end='', file=sys.stderr)

    plan_process.wait()

    if plan_process.returncode != 0:
        os.chdir(original_dir)
        return False, "", "Plan failed"

    # Ask for confirmation unless auto-approve
    if not auto_approve:
        print("\n" + "=" * 50)
        apply_choice = input("\n🔄 Apply these changes? (y/n): ").strip().lower()
        if apply_choice not in ['y', 'yes']:
            print("⏭️  Skipping apply.")
            os.chdir(original_dir)
            return True, "Plan completed, apply skipped", ""

    # Run apply
    cmd_apply = ["terraform", "apply", "-auto-approve"] if auto_approve else ["terraform", "apply"]
    for var_name, var_value in variables.items():
        cmd_apply.extend(["-var", f"{var_name}={var_value}"])

    print("\n🔄 Running terraform apply...")
    print("   Command:", " ".join(cmd_apply))
    print("-" * 50)

    apply_process = subprocess.Popen(
        cmd_apply,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    apply_stdout = []
    apply_stderr = []

    while True:
        line = apply_process.stdout.readline()
        if not line:
            break
        print(line, end='')
        apply_stdout.append(line)

    for line in apply_process.stderr:
        print(line, end='', file=sys.stderr)
        apply_stderr.append(line)

    apply_process.wait()

    os.chdir(original_dir)

    if apply_process.returncode == 0:
        print("\n✅ Terraform apply successful!")
        return True, ''.join(apply_stdout), ''.join(apply_stderr)
    else:
        print("\n❌ Terraform apply failed!")
        return False, ''.join(apply_stdout), ''.join(apply_stderr)


def interactive_terraform_session():
    """Interactive Terraform session with variable management."""
    print("\n" + "=" * 60)
    print("🔄 INTERACTIVE TERRAFORM SESSION")
    print("=" * 60)

    # Get directory
    tf_dir = input("\n📁 Terraform directory (default: .): ").strip() or "."

    # Check if directory exists and has .tf files
    if not os.path.exists(tf_dir):
        print(f"❌ Directory '{tf_dir}' does not exist!")
        return

    tf_files = [f for f in os.listdir(tf_dir) if f.endswith('.tf')]
    if not tf_files:
        print(f"⚠️  No .tf files found in '{tf_dir}'")
        return

    print("\n🔧 Choose action:")
    print("  1. Run terraform plan (with variable prompts)")
    print("  2. Run terraform apply (with variable prompts and confirmation)")
    print("  3. Run terraform apply -auto-approve")
    print("  4. Exit")

    choice = input("\nEnter choice (1-4): ").strip()

    if choice == '1':
        success, output, error = run_terraform_plan_only(tf_dir)
        if not success:
            print("\n💡 Troubleshooting tips:")
            print("  • Check your Terraform syntax: terraform validate")
            print("  • Check AWS credentials: aws configure")
            print("  • Review the error message above")
    elif choice == '2':
        success, output, error = run_terraform_apply(tf_dir, auto_approve=False)
        if success:
            print("\n🎉 Infrastructure deployed successfully!")
        else:
            print("\n💡 Troubleshooting tips:")
            print("  • Check your AWS credentials")
            print("  • Verify IAM permissions")
            print("  • Run: terraform plan -detailed-exitcode")
    elif choice == '3':
        success, output, error = run_terraform_apply(tf_dir, auto_approve=True)
        if success:
            print("\n🎉 Infrastructure deployed successfully!")
        else:
            print("\n💡 Troubleshooting tips:")
            print("  • Check your AWS credentials")
            print("  • Verify IAM permissions")
            print("  • Run: terraform plan -detailed-exitcode")
    else:
        print("👋 Exiting Terraform session.")


# ============================================
# MAIN FUNCTION
# ============================================

def main():
    """Main program with interactive Terraform support."""
    print("\n" + "=" * 60)
    print("=== IMPOSTOR SYNDROME DEFENSE SYSTEM ===")
    print("=" * 60 + "\n")

    # Get user info
    name = input("Enter your name: ").strip() or "Engineer"

    print_slow(f"\nScanning {name}'s cloud engineering progress...\n")
    time.sleep(1)

    # NOW skills is defined and available
    learned = random.sample(skills, k=random.randint(4, len(skills)))

    print("Detected skills:")
    for skill in learned:
        print(f"  ✅ {skill}")
        time.sleep(0.2)

    print("\nThreat detected: Impostor Syndrome")
    time.sleep(1)

    print("\nDeploying countermeasures...\n")
    time.sleep(1)

    print_slow(random.choice(truths))
    print_slow(random.choice(truths))
    print_slow(random.choice(warnings))

    # Interactive Terraform session
    print("\n" + "=" * 50)
    run_tf = input("\n🛠️  Start interactive Terraform session? (y/n): ").strip().lower()

    if run_tf in ['y', 'yes']:
        interactive_terraform_session()
    else:
        print("\n📚 Continuing with motivation only...")

    print("\n🎯 Final assessment:")
    print(f"✅ {name}, you are not an impostor.")
    print("✅ You are a student becoming an engineer.")
    print("✅ Keep building.\n")

    print("Broken Theo says: Read the logs. Then win.\n")


# ============================================
# SCRIPT ENTRY POINT
# ============================================

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Exiting... Remember: You've got this!")
        sys.exit(0)