#!/usr/bin/env python3
"""
Imposter Syndrome Defense

Reads canonical Terraform skill definitions, scans the current Terraform
deployment, displays detected skills, and optionally runs the lab Terraform
plan/apply flow with encouragement that is only slightly unhinged.
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import random
import re
import subprocess
import sys
import threading
import time
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


# ================================================================
# DISPLAY SETTINGS
# ================================================================

TYPE_DELAY = float(os.getenv("TYPE_DELAY", "0.025"))
LINE_DELAY = float(os.getenv("LINE_DELAY", "0.18"))
PAUSE_SHORT = float(os.getenv("PAUSE_SHORT", "0.35"))
PAUSE_MEDIUM = float(os.getenv("PAUSE_MEDIUM", "0.75"))
PAUSE_LONG = float(os.getenv("PAUSE_LONG", "1.5"))
DISABLE_TYPEWRITER = os.getenv("NO_TYPEWRITER", "false").lower() == "true"
TERRAFORM_STREAM_INTERVAL = int(os.getenv("TERRAFORM_STREAM_INTERVAL", "60"))

TERRAFORM_WAIT_MESSAGES = [
    "Showing signs of life...",
    "Terraform is thinking very important thoughts...",
    "Nothing's broken. Probably...",
    "Doing Terraform stuff with my Terraform friends...",
    "Still working...",
    "Infrastructure takes time...",
    "No errors yet. Don't get excited...",
    "Still provisioning. The Terraform gods have acknowledged your existence...",
    "Things are happening. Expensive things, potentially...",
    "Don't rage quit yet...",
    "Keep praying...",
]


# ================================================================
# CLI COLORS AND LOGGING
# ================================================================

class Colors:
    """ANSI color codes."""

    GREEN = "\033[92m"
    RED = "\033[91m"
    CYAN = "\033[96m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    WHITE = "\033[97m"
    BOLD = "\033[1m"
    RESET = "\033[0m"

    @classmethod
    def enabled(cls) -> bool:
        if os.getenv("FORCE_COLOR", "false").lower() == "true":
            return True

        if os.getenv("NO_COLOR", "false").lower() == "true":
            return False

        return sys.stdout.isatty() and os.getenv("TERM", "") != "dumb"


def color(text: str, ansi: str) -> str:
    if Colors.enabled():
        return f"{ansi}{text}{Colors.RESET}"
    return text


def pause(seconds: float = PAUSE_SHORT, always: bool = False) -> None:
    """Pause for CLI pacing without slowing automated validation."""

    if always or not DISABLE_TYPEWRITER:
        time.sleep(seconds)


class Headers:
    """Header formatting aligned with the lab scripts."""

    @staticmethod
    def header(title: str, ansi: str = Colors.BOLD) -> None:
        width = 60
        line = "=" * width
        print(color(f"\n{line}", ansi))
        print(color(title.center(width), ansi))
        print(color(line, ansi))

    @staticmethod
    def sub_header(title: str, ansi: str = Colors.BLUE) -> None:
        width = 50
        line = "-" * width
        print(color(f"\n{line}", ansi))
        print(color(f"  {title}", ansi))
        print(color(line, ansi))

    @staticmethod
    def short_header(title: str, ansi: str = Colors.CYAN) -> None:
        print(color(f"\n--- {title} ---", ansi))


class Logger:
    """Consistent status output."""

    @staticmethod
    def info(message: str) -> None:
        print(f"{color('[INFO]', Colors.CYAN)} {color(message, Colors.WHITE)}")

    @staticmethod
    def step(message: str) -> None:
        print(f"\n{color('[STEP]', Colors.BLUE)} {color(message, Colors.WHITE)}")

    @staticmethod
    def success(message: str) -> None:
        print(color(f"OK: {message}", Colors.GREEN))

    @staticmethod
    def warn(message: str) -> None:
        print(f"{color('[WARN]', Colors.YELLOW)} {color(message, Colors.WHITE)}")

    @staticmethod
    def error(message: str) -> None:
        print(color(f"[ERROR] {message}", Colors.RED))

    @staticmethod
    def alert(message: str) -> None:
        print(color(f"[ALERT] {message}", Colors.RED))


def type_text(
    text: str,
    delay: float = TYPE_DELAY,
    ansi: str | None = None,
    end: str = "\n",
) -> None:
    """Print text with a small typewriter effect."""

    if text == "":
        print(end=end)
        return

    if DISABLE_TYPEWRITER or delay <= 0:
        print(color(text, ansi) if ansi else text, end=end)
        return

    if ansi and Colors.enabled():
        print(ansi, end="", flush=True)

    for char in text:
        print(char, end="", flush=True)
        time.sleep(delay)

    if ansi and Colors.enabled():
        print(Colors.RESET, end="", flush=True)

    print(end=end, flush=True)


def type_lines(
    lines: Iterable[str],
    delay: float = TYPE_DELAY,
    line_delay: float = LINE_DELAY,
    ansi: str | None = None,
) -> None:
    """Print several lines with typewriter pacing."""

    for line in lines:
        type_text(line, delay=delay, ansi=ansi)
        if line_delay > 0 and not DISABLE_TYPEWRITER:
            time.sleep(line_delay)


# ================================================================
# DATA MODELS
# ================================================================

@dataclass(frozen=True)
class TerraformBlock:
    """A Terraform resource or data block discovered in HCL."""

    kind: str
    block_type: str
    name: str
    source: Path
    skills: tuple[str, ...] = ()

    @property
    def address(self) -> str:
        return f'{self.kind} "{self.block_type}" "{self.name}"'


@dataclass(frozen=True)
class DetectedSkill:
    """A skill detected in student Terraform with supporting evidence."""

    name: str
    evidence: tuple[str, ...]


# ================================================================
# PATH HELPERS
# ================================================================

def default_terraform_dir() -> Path:
    """Resolve the Terraform root from this script location."""

    return Path(__file__).resolve().parents[2]


def resolve_paths(terraform_dir: Path) -> tuple[Path, Path, Path]:
    """Return canonical skill, quote, and tfvars paths."""

    script_dir = Path(__file__).resolve().parent
    skills_file = script_dir / "assets" / "skills" / "skills.tf"
    quotes_file = script_dir / "assets" / "quotes" / "quotes.json"
    tfvars_file = terraform_dir / "chewbacca.tfvars"

    return skills_file, quotes_file, tfvars_file


# ================================================================
# TERRAFORM PARSING
# ================================================================

BLOCK_START_PATTERN = re.compile(
    r'(?m)^(resource|data)\s+"([^"]+)"\s+"([^"]+)"\s*\{'
)

SKILL_BLOCK_PATTERN = re.compile(
    r'((?:#SKILL: .+\n)+)(resource|data)\s+"([^"]+)"\s+"([^"]+)"\s*\{'
)


def strip_hcl_comments(text: str) -> str:
    """Remove common HCL comments before scanning deployment files."""

    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)

    cleaned_lines = []
    for line in text.splitlines():
        stripped = line.lstrip()

        if stripped.startswith("#") or stripped.startswith("//"):
            cleaned_lines.append("")
            continue

        cleaned_lines.append(line)

    return "\n".join(cleaned_lines)


def should_scan_tf_file(path: Path, terraform_dir: Path) -> bool:
    """Return whether a Terraform file is student/deployment input."""

    ignored_parts = {
        ".terraform",
        ".git",
        "scripts",
        "assets",
        "lambda",
    }

    try:
        relative = path.relative_to(terraform_dir)
    except ValueError:
        return False

    return not any(part in ignored_parts for part in relative.parts)


def iter_terraform_files(terraform_dir: Path) -> Iterable[Path]:
    """Yield active Terraform files to assess."""

    for path in sorted(terraform_dir.rglob("*.tf")):
        if should_scan_tf_file(path, terraform_dir):
            yield path


def extract_blocks_from_file(path: Path, terraform_dir: Path) -> list[TerraformBlock]:
    """Extract top-level resource and data blocks from one Terraform file."""

    text = strip_hcl_comments(path.read_text())
    blocks = []

    for match in BLOCK_START_PATTERN.finditer(text):
        kind, block_type, name = match.groups()
        blocks.append(
            TerraformBlock(
                kind=kind,
                block_type=block_type,
                name=name,
                source=path.relative_to(terraform_dir),
            )
        )

    return blocks


def parse_skill_contract(skills_file: Path) -> list[TerraformBlock]:
    """Parse the canonical skills.tf contract."""

    if not skills_file.exists():
        raise FileNotFoundError(
            "Missing skill definition file: "
            f"{skills_file}"
        )

    text = skills_file.read_text()
    blocks = []

    for match in SKILL_BLOCK_PATTERN.finditer(text):
        raw_tags, kind, block_type, name = match.groups()
        skills = tuple(
            line.removeprefix("#SKILL: ").strip()
            for line in raw_tags.splitlines()
            if line.startswith("#SKILL: ")
        )

        blocks.append(
            TerraformBlock(
                kind=kind,
                block_type=block_type,
                name=name,
                source=skills_file,
                skills=skills,
            )
        )

    if not blocks:
        raise ValueError(
            "Skill definition file contains no tagged Terraform blocks."
        )

    return blocks


def build_skill_indexes(
    contract_blocks: list[TerraformBlock],
) -> tuple[dict[tuple[str, str, str], tuple[str, ...]], dict[tuple[str, str], tuple[str, ...]]]:
    """Build exact and type-level skill lookup indexes."""

    exact: dict[tuple[str, str, str], tuple[str, ...]] = {}
    by_type: dict[tuple[str, str], set[str]] = {}

    for block in contract_blocks:
        exact[(block.kind, block.block_type, block.name)] = block.skills
        by_type.setdefault(
            (block.kind, block.block_type),
            set(),
        ).update(block.skills)

    type_index = {
        key: tuple(sorted(value))
        for key, value in by_type.items()
    }

    return exact, type_index


def scan_detected_skills(
    terraform_dir: Path,
    contract_blocks: list[TerraformBlock],
) -> list[DetectedSkill]:
    """Compare student Terraform with the skill contract."""

    exact_index, type_index = build_skill_indexes(contract_blocks)
    skill_evidence: dict[str, set[str]] = {}

    for tf_file in iter_terraform_files(terraform_dir):
        for block in extract_blocks_from_file(tf_file, terraform_dir):
            exact_key = (
                block.kind,
                block.block_type,
                block.name,
            )
            type_key = (
                block.kind,
                block.block_type,
            )

            skills = (
                exact_index.get(exact_key)
                or type_index.get(type_key)
                or ()
            )

            for skill in skills:
                skill_evidence.setdefault(
                    skill,
                    set(),
                ).add(f"{block.block_type}.{block.name}")

    detected = [
        DetectedSkill(
            name=skill,
            evidence=tuple(sorted(evidence)),
        )
        for skill, evidence in sorted(skill_evidence.items())
    ]

    return detected


# ================================================================
# QUOTES
# ================================================================

def load_quotes(quotes_file: Path) -> list[dict[str, object]]:
    """Load quote objects. Missing quotes should not block assessment."""

    if not quotes_file.exists():
        Logger.warn(
            f"Quotes file not found: {quotes_file}. "
            "Continuing without a quote."
        )
        return []

    try:
        payload = json.loads(quotes_file.read_text())
    except json.JSONDecodeError as error:
        Logger.warn(
            f"Quotes file is not valid JSON: {error}. "
            "Continuing without a quote."
        )
        return []

    if isinstance(payload, dict):
        quotes = payload.get("quotes", [])
    else:
        quotes = payload

    if not isinstance(quotes, list):
        Logger.warn(
            "Quotes file does not contain a quote list. "
            "Continuing without a quote."
        )
        return []

    normalized = []
    for item in quotes:
        if isinstance(item, str):
            normalized.append(
                {
                    "text": item,
                    "author": None,
                    "speaker": None,
                    "source": None,
                }
            )
        elif isinstance(item, dict) and item.get("text"):
            normalized.append(item)

    return normalized


def format_name_list(name_value: object) -> str:
    """Format comma-separated names the same way the quotes web app does."""

    if not name_value:
        return ""

    names = [
        item.strip()
        for item in str(name_value).split(",")
        if item.strip()
    ]

    if not names:
        return ""

    if len(names) == 1:
        return names[0]

    return f"{', '.join(names[:-1])} and {names[-1]}"


def get_quote_attribution(quote: dict[str, object]) -> tuple[str, list[str]]:
    """Return primary and secondary attribution lines."""

    speaker = str(quote.get("speaker") or "").strip()
    author = str(quote.get("author") or "").strip()
    source = str(quote.get("source") or "").strip()

    primary = ""
    secondary: list[str] = []

    if speaker:
        primary = format_name_list(speaker)

        if author and author != speaker:
            if source:
                secondary = [
                    f"from {source}",
                    f"by {format_name_list(author)}",
                ]
            else:
                secondary = [
                    f"from {format_name_list(author)}",
                ]
        elif source:
            secondary = [
                f"from {source}",
            ]

    elif author:
        primary = format_name_list(author)

        if source:
            secondary = [
                f"from {source}",
            ]

    elif source:
        primary = source

    else:
        primary = "Unknown"

    return primary, secondary


def format_quote(quote: dict[str, object]) -> str:
    """Format a quote object using the repo quote-display structure."""

    text = str(quote.get("text", "")).strip()
    primary, secondary = get_quote_attribution(quote)

    lines = [
        f'"{text}"',
        f"- {primary}",
    ]

    lines.extend(secondary)

    return "\n".join(lines)


def choose_quote(quotes: list[dict[str, object]]) -> str | None:
    """Choose one quote for the run."""

    if not quotes:
        return None

    return format_quote(random.choice(quotes))


# ================================================================
# DISPLAY
# ================================================================

def display_opening(name: str) -> None:
    """Open with the alert before any assessment work begins."""

    pause(PAUSE_SHORT)
    type_lines(
        [
            f"Initializing countermeasures for {name}...",
            "Reviewing Terraform evidence to eliminate self-doubt.",
        ],
        delay=0.02,
    )
    pause(PAUSE_MEDIUM)


def display_detected_skills(
    detected: list[DetectedSkill],
    verbose: bool = False,
) -> None:
    """Display detected skills grouped with supporting resource evidence."""

    Headers.sub_header("Detected Terraform Skills")

    if not detected:
        Logger.warn("No skills were detected from the current Terraform files.")
        pause(PAUSE_SHORT)
        return

    Logger.info(f"Detected {len(detected)} skill categories.")
    pause(PAUSE_SHORT)

    visible_items = detected if verbose else detected[:18]
    evidence_limit = 6 if verbose else 3

    for item in visible_items:
        print(color(item.name, Colors.GREEN))
        for evidence in item.evidence[:evidence_limit]:
            type_text(f"  - {evidence}", delay=0.006)

        if len(item.evidence) > evidence_limit:
            type_text(
                f"  - ... {len(item.evidence) - evidence_limit} more",
                delay=0.006,
            )

        pause(0.12)

    if not verbose and len(detected) > len(visible_items):
        Logger.info(
            f"{len(detected) - len(visible_items)} additional skills hidden. "
            "Run with --verbose-skills to show all evidence."
        )
        pause(PAUSE_SHORT)


def display_imposter_message(name: str, quote: str | None) -> None:
    """Display the imposter syndrome transition message."""

    Headers.sub_header("Imposter Syndrome Check")

    type_lines(
        [
            "Terraform is not judging you.",
            "It is helping you.",
            "",
            "Errors are not insults.",
            "They are instructions.",
        ]
    )
    pause(PAUSE_MEDIUM)

    if quote:
        Headers.short_header("Remember", Colors.CYAN)
        type_text(quote, delay=0.012)
        pause(PAUSE_MEDIUM)

    print()


def display_continue_encouragement(name: str) -> None:
    """Display the short green encouragement line."""

    type_text(
        f"{name}, you are still allowed to build anyway.",
        ansi=Colors.GREEN,
    )


def display_failure_encouragement(name: str) -> None:
    """Display encouragement after an expected learning failure."""

    Headers.sub_header("Final Assessment")

    type_lines(
        [
            f"{name}, you are not an impostor.",
            "You are a student becoming an engineer.",
            "Keep building.",
        ],
        ansi=Colors.GREEN,
    )
    pause(PAUSE_MEDIUM)

    Headers.short_header("Broken Theo Says", Colors.CYAN)
    type_text("Make mistakes, read the logs, then win.")


def display_success(name: str) -> None:
    """Display success message after Terraform apply succeeds."""

    Headers.sub_header("Terraform Apply Complete")

    Logger.success("Congratulations, Terraform apply succeeded.")
    pause(PAUSE_SHORT)

    type_lines(
        [
            "",
            "Now test your deployment and make sure it really works.",
            '"Apply complete" only means Terraform finished.',
            "The best engineers verify what they built.",
            "",
            f"{name}, you are not an impostor.",
            "Bad news: you've officially run out of excuses.",
        ]
    )


# ================================================================
# TERRAFORM EXECUTION
# ================================================================

def read_process_output(
    process: subprocess.Popen[str],
    output_queue: queue.Queue[str | None],
) -> None:
    """Continuously read Terraform output without blocking the timer."""

    if process.stdout is None:
        output_queue.put(None)
        return

    for line in process.stdout:
        output_queue.put(line)

    output_queue.put(None)


def drain_output_queue(
    output_queue: queue.Queue[str | None],
    output_lines: list[str],
    recent_lines: deque[str],
) -> bool:
    """Drain queued process output and return whether the reader finished."""

    reader_finished = False

    while True:
        try:
            line = output_queue.get_nowait()
        except queue.Empty:
            break

        if line is None:
            reader_finished = True
            continue

        output_lines.append(line)

        stripped = line.strip()
        if stripped:
            recent_lines.append(stripped)

    return reader_finished


def display_terraform_stream_snippet(
    label: str,
    recent_lines: deque[str],
    message: str,
) -> None:
    """Show a small Terraform output snippet during long-running commands."""

    type_text(message)
    pause(PAUSE_MEDIUM)

    if not recent_lines:
        Logger.warn(
            "Terraform has not produced output recently. "
            "If this continues, check for prompts, provider waits, or state locks."
        )
        return

    Headers.short_header("Latest Terraform Output", Colors.CYAN)

    for line in list(recent_lines)[-6:]:
        print(color(f"  {line}", Colors.WHITE))


def run_command_with_wait(
    command: list[str],
    cwd: Path,
    label: str,
) -> tuple[int, str]:
    """Run a command while showing elapsed time and periodic output snippets."""

    Logger.step(label)

    process = subprocess.Popen(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    output_queue: queue.Queue[str | None] = queue.Queue()
    output_lines: list[str] = []
    recent_lines: deque[str] = deque(maxlen=12)
    reader = threading.Thread(
        target=read_process_output,
        args=(process, output_queue),
        daemon=True,
    )
    reader.start()

    start = time.monotonic()
    next_snippet = TERRAFORM_STREAM_INTERVAL
    message_index = 0
    dots = 1

    while process.poll() is None:
        drain_output_queue(
            output_queue=output_queue,
            output_lines=output_lines,
            recent_lines=recent_lines,
        )

        elapsed = int(time.monotonic() - start)
        print(
            f"\r[{elapsed:02d}s] {label} still running{' .' * dots}",
            end="",
            flush=True,
        )

        if (
            TERRAFORM_STREAM_INTERVAL > 0
            and elapsed >= next_snippet
        ):
            print("\r" + " " * 90 + "\r", end="")
            display_terraform_stream_snippet(
                label=label,
                recent_lines=recent_lines,
                message=TERRAFORM_WAIT_MESSAGES[
                    message_index % len(TERRAFORM_WAIT_MESSAGES)
                ],
            )
            message_index += 1
            next_snippet += TERRAFORM_STREAM_INTERVAL

        dots = 1 if dots >= 3 else dots + 1
        time.sleep(1)

    process.wait()
    reader.join(timeout=2)

    while drain_output_queue(
        output_queue=output_queue,
        output_lines=output_lines,
        recent_lines=recent_lines,
    ):
        pass

    output = "".join(output_lines)
    print("\r" + " " * 90 + "\r", end="")

    return process.returncode, output


def ask_yes_no(question: str, default: bool = False) -> bool:
    """Ask an interactive yes/no question."""

    suffix = " [Y/n]: " if default else " [y/N]: "

    while True:
        answer = input(question + suffix).strip().lower()

        if not answer:
            return default

        if answer in {"y", "yes"}:
            return True

        if answer in {"n", "no"}:
            return False

        Logger.warn("Please answer yes or no.")


def run_terraform(terraform_dir: Path, tfvars_file: Path, name: str) -> bool | None:
    """Run Terraform apply directly or plan first using Chewbacca tfvars."""

    if not tfvars_file.exists():
        Logger.error("Terraform apply failed.")
        pause(PAUSE_SHORT)
        type_lines(
            [
                "",
                "Where's Chewbacca?",
                f"(missing {tfvars_file.name})",
            ],
            ansi=Colors.RED,
        )
        print()
        pause(PAUSE_SHORT)
        display_continue_encouragement(name)
        return False

    plan_file = terraform_dir / "chewbacca.tfplan"
    auto_apply = ask_yes_no("Run Terraform Auto Apply?")

    if auto_apply:
        type_text("Plan declined. Consequences accepted.")
        pause(PAUSE_MEDIUM)
        type_text("Plan review skipped", ansi=Colors.YELLOW)
        type_text('"Nothing teaches architecture like consequences."')
        pause(PAUSE_MEDIUM)

        apply_command = [
            "terraform",
            "apply",
            "-input=false",
            "-auto-approve",
            f"-var-file={tfvars_file.name}",
        ]

        apply_code, apply_output = run_command_with_wait(
            command=apply_command,
            cwd=terraform_dir,
            label="Running Terraform auto apply",
        )

        if apply_code != 0:
            type_text("Terraform has spoken.")
            pause(PAUSE_SHORT)
            Headers.sub_header("Terraform Output")
            print(apply_output.strip())
            Logger.error("Terraform apply failed.")
            return False

        return True

    type_text("Planning before applying? What are you, a professional?")
    pause(PAUSE_MEDIUM)

    plan_command = [
        "terraform",
        "plan",
        "-input=false",
        f"-var-file={tfvars_file.name}",
        f"-out={plan_file.name}",
    ]

    plan_code, plan_output = run_command_with_wait(
        command=plan_command,
        cwd=terraform_dir,
        label="Generating Terraform plan",
    )

    if plan_code != 0:
        type_text("Terraform has spoken.")
        pause(PAUSE_SHORT)
        Headers.sub_header("Terraform Output")
        print(plan_output.strip())
        Logger.error("Terraform plan failed.")
        return False

    type_text("Terraform plan generated successfully.", ansi=Colors.GREEN)
    pause(PAUSE_SHORT)
    Headers.sub_header("Terraform Plan Output")
    print(plan_output.strip())
    pause(PAUSE_MEDIUM)

    if not ask_yes_no("Apply this Terraform plan?"):
        type_text("You reviewed the plan and lived to tell the tale.")
        pause(PAUSE_SHORT)
        type_text("Stop doubting yourself. Come back when you are ready to apply.")
        return None

    apply_command = [
        "terraform",
        "apply",
        "-input=false",
        plan_file.name,
    ]

    apply_code, apply_output = run_command_with_wait(
        command=apply_command,
        cwd=terraform_dir,
        label="Applying reviewed Terraform plan",
    )

    if apply_code != 0:
        type_text("Terraform has spoken.")
        pause(PAUSE_SHORT)
        Headers.sub_header("Terraform Output")
        print(apply_output.strip())
        Logger.error("Terraform apply failed.")
        return False

    return True


# ================================================================
# MAIN
# ================================================================

def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            "Detect Terraform skills and run the Imposter Syndrome "
            "Defense workflow."
        )
    )

    parser.add_argument(
        "--name",
        default=None,
        help="Name to display in the encouragement messages.",
    )

    parser.add_argument(
        "--terraform-dir",
        default=str(default_terraform_dir()),
        help="Terraform directory to scan and run.",
    )

    parser.add_argument(
        "--skip-terraform",
        action="store_true",
        help="Scan skills and skip Terraform plan/apply.",
    )

    parser.add_argument(
        "--verbose-skills",
        action="store_true",
        help="Show all detected skills and all supporting evidence.",
    )

    return parser.parse_args()


def main() -> int:
    """Run the Imposter Syndrome Defense workflow."""

    args = parse_args()
    terraform_dir = Path(args.terraform_dir).resolve()
    skills_file, quotes_file, tfvars_file = resolve_paths(terraform_dir)

    Logger.alert("Imposter Syndrome detected.")
    pause(PAUSE_LONG, always=True)
    Headers.header("IMPOSTER SYNDROME DEFENSE")

    name = args.name or input("Enter your name: ").strip() or "Engineer"

    display_opening(name)

    Logger.info(f"Terraform directory: {terraform_dir}")
    Logger.info(f"Skill contract: {skills_file}")
    Logger.info(f"Quotes file: {quotes_file}")

    if not terraform_dir.exists():
        Logger.error(f"Terraform directory does not exist: {terraform_dir}")
        return 1

    try:
        contract_blocks = parse_skill_contract(skills_file)
    except (FileNotFoundError, ValueError) as error:
        Logger.error("Imposter Syndrome configuration error.")
        print(error)
        return 1

    detected = scan_detected_skills(
        terraform_dir=terraform_dir,
        contract_blocks=contract_blocks,
    )

    display_detected_skills(
        detected,
        verbose=args.verbose_skills,
    )

    quotes = load_quotes(quotes_file)
    display_imposter_message(
        name=name,
        quote=choose_quote(quotes),
    )

    if args.skip_terraform:
        Logger.warn("Terraform execution skipped by request.")
        display_failure_encouragement(name)
        return 0

    terraform_succeeded = run_terraform(
        terraform_dir=terraform_dir,
        tfvars_file=tfvars_file,
        name=name,
    )

    if terraform_succeeded is True:
        display_success(name)
        return 0

    if terraform_succeeded is None:
        return 0

    display_failure_encouragement(name)
    return 1


if __name__ == "__main__":
    sys.exit(main())
