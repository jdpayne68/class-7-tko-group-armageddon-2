# Gen2X Security Engineering Platform

# INSTALL.md

## `/lab12d` — Agent 10: Domain Models, Trust, Response, and Reporting

---

## Which Document Do I Need?

Agent 10 ships with three documents. They answer different questions.

```text
readme.md
    What is Agent 10, and why does it exist?

playbook.md
    How do I develop, test, and integrate models correctly?

install.md          ← you are here
    How do I get Agent 10 running on my machine?
```

Some students only need the playbook.

Some students only need this file.

Read whichever answers your current question.

A deeper reference on the validation library lives at:

```text
general/Pydantic_Explanation.md
```

---

# Overview

Agent 10 is a **library, not a service**.

There is no Lambda to deploy and no AWS account required.

Installing Agent 10 means:

```text
1. Get the code.

2. Create a Python environment.

3. Install dependencies.

4. Verify the package imports.

5. Run the test suite.

6. Build your first model.
```

Once installed, operational agents (providers, fusion, reporting)
import Agent 10's models instead of inventing their own structures.

---

# Folder Structure

```text
lab12d/

├── readme.md                    ← what Agent 10 is
├── playbook.md                  ← how to build within it
├── install.md                   ← you are here
├── requirements.txt             ← dependencies
│
├── models/                      ← Agent 10 itself
│   ├── __init__.py
│   ├── base_model.py            ← Gen2XModel (pydantic base)
│   ├── enums/                   ← the vocabulary (7 domain modules)
│   ├── indicator.py
│   ├── provider.py
│   ├── evidence.py
│   ├── threat.py
│   ├── response.py
│   └── report.py
│
├── utils/
│   └── time.py                  ← utc_now() — aware UTC timestamps
│
├── tests/
│   ├── test_enums_public_api.py ← guards the vocabulary contract
│   └── test_models_roundtrip.py ← guards the serialization contract
│
├── agents/                      ← operational agents (fusion, report)
├── providers/                   ← provider adapters
├── general/                     ← reference documents
└── env/                         ← sample environment values
```

---

# Prerequisites

1. **Python 3.12** (3.10 or newer works; the lab is developed on 3.12).

   ```bash
   python3 --version
   ```

2. **git**

3. **pip**

No AWS credentials are required for Agent 10 itself.

---

# Step 1 — Get the Code

```bash
git clone https://github.com/BalericaAI/armageddon.git

cd armageddon/SEIR_Foundations/lab12/lab12d
```

Important

Every command in this document runs from the `lab12d` directory.

The packages (`models`, `utils`, `tests`) resolve relative to it.

---

# Step 2 — Create a Virtual Environment

Keep lab dependencies isolated from your system Python.

```bash
python3 -m venv .venv
```

Activate it.

macOS / Linux:

```bash
source .venv/bin/activate
```

Windows (PowerShell):

```powershell
.venv\Scripts\Activate.ps1
```

Your prompt should now show `(.venv)`.

---

# Step 3 — Install Dependencies

```bash
pip install -r requirements.txt
```

This installs **pydantic v2** — the validation engine beneath
`Gen2XModel`.

To run the test suite through pytest (optional but recommended):

```bash
pip install pytest
```

---

# Step 4 — Verify the Installation

From the `lab12d` directory:

```bash
python3 -c "
from models.enums import ThreatSeverity
from models.evidence import ThreatEvidence
from models.base_model import Gen2XModel
from utils.time import utc_now

print('Vocabulary :', ThreatSeverity.CRITICAL.describe())
print('Timestamp  :', utc_now().isoformat())
print('Agent 10 is installed correctly.')
"
```

Expected output:

```text
Vocabulary : Severe impact requiring immediate attention.
Timestamp  : 2026-08-11T20:30:00.000000+00:00
Agent 10 is installed correctly.
```

---

# Step 5 — Run the Test Suite

Two test files guard Agent 10's contracts.

**The vocabulary contract** — every enum a module declares public
must be exported by the package, and every export must exist:

```bash
python3 tests/test_enums_public_api.py
```

**The serialization contract** — every model must survive
`to_dict()` → `from_dict()` intact, including nested models,
enums, datetimes, and sets:

```bash
python3 tests/test_models_roundtrip.py
```

Or run everything through pytest:

```bash
python3 -m pytest tests/ -q
```

Expected:

```text
......... 
9 passed
```

If the suite passes, your installation is complete.

---

# Step 6 — Build Your First Model

This is the "hello world" of Agent 10 — one piece of evidence,
validated, serialized, and reconstructed.

Save as `first_model.py` in the `lab12d` directory and run it:

```python
from models.enums import (
    IndicatorSource,
    IndicatorType,
    PlatformType,
    ProviderType,
    ThreatCondition,
    ThreatSeverity,
)
from models.evidence import (
    EvidenceContext,
    EvidenceIdentity,
    EvidenceIndicator,
    ThreatEvidence,
)

evidence = ThreatEvidence(
    identity=EvidenceIdentity(
        evidence_id="ev-001",
        provider_name="GitHub",
        provider_type=ProviderType.COMMERCIAL,
        provider_platform=PlatformType.GITHUB,
    ),
    indicator=EvidenceIndicator(
        indicator_type=IndicatorType.TOKEN_ID,
        indicator_value="ghp_example",
        indicator_source=IndicatorSource.EXTERNAL_API,
        condition=ThreatCondition.TOKEN_EXPOSURE,
    ),
    context=EvidenceContext(
        severity=ThreatSeverity.CRITICAL,
    ),
)

print(evidence.describe())

restored = ThreatEvidence.from_dict(evidence.to_dict())

print("Round trip:", restored == evidence)
```

Expected output:

```text
GitHub observed TOKEN_EXPOSURE for ghp_example
Round trip: True
```

Then follow the playbook's student workflow (section 49):

```text
READ → TRACE → INSTANTIATE → BREAK → MUTATE →
SERIALIZE → COMPOSE → INTEGRATE → EXPLAIN
```

Try to break your model.

Feed it an empty provider name.

Feed it a field that does not exist.

Watch the contract defend itself.

---

# Import Conventions

Agent 10 follows two import rules.

**Vocabulary comes from the package, not the module:**

```python
from models.enums import ThreatSeverity        # correct

from models.enums.threat_enums import ThreatSeverity   # avoid
```

**Timestamps come from one place:**

```python
from utils.time import utc_now
```

Every timestamp in Gen2X is timezone-aware UTC.

`datetime.utcnow()` returns a naive datetime and must not be used —
naive and aware datetimes cannot be compared, and the mixture
fails at runtime.

---

# Adding to Agent 10

When your lab work grows the architecture, follow the playbook.

The short version:

```text
New vocabulary
    Add members to an existing enum, or a new module
    under models/enums/. Export it from the package
    __init__.py. The vocabulary contract test discovers
    new modules automatically — run it.

New model
    Inherit Gen2XModel. Declare fields using existing
    enums. Add field_validators for structure, never
    for analysis. (Playbook sections 4–16.)

New provider agent
    Collect native data, map it into Gen2X enums,
    construct ThreatEvidence, submit to aggregation.
    (Playbook section 29.)
```

Then test in the playbook's recommended order — enums first,
composed models last (section 23).

---

# Troubleshooting

**`ModuleNotFoundError: No module named 'models'`**

You are not running from the `lab12d` directory. Every command
in this document assumes it. Alternatively, add `lab12d` to
`PYTHONPATH`.

**`ImportError: The Gen2X models package requires pydantic`**

Dependencies are not installed in the active environment.
Confirm `(.venv)` appears in your prompt, then repeat Step 3.

**`ValidationError: ... Extra inputs are not permitted`**

You passed a field the model does not declare — usually a typo.
Agent 10 models are configured with `extra="forbid"` so mistakes
fail loudly instead of being silently absorbed. Check the field
name against the model definition.

**`ValidationError` on a value you thought was valid**

Read the complete message — pydantic names the exact field and
rule. Then follow the playbook's debugging sequence (section 25):
identify the file, the model, the field, fix one thing, run again.

**`AttributeError: ... has no attribute 'SOME_MEMBER'`**

The enum member does not exist. Check the vocabulary first
(playbook section 5) — list what actually exists:

```python
from models.enums import ThreatCondition
print(ThreatCondition.names())
```

**`python3 -m pytest` says no module named pytest**

pytest is optional; install it (`pip install pytest`) or run the
test files directly — both support standalone execution.

---

# Definition of Installed

```text
[ ] Python 3.10+ available

[ ] Virtual environment active

[ ] pip install -r requirements.txt succeeded

[ ] Verification import prints correctly (Step 4)

[ ] Both test files pass (Step 5)

[ ] first_model.py round-trips (Step 6)
```

Only then start the playbook.

---

# Chewbacca's Commentary 🐾

        Installation
        
        is not
        
        the lab.
        
        Installation
        
        is the part
        
        where your machine
        
        agrees
        
        to speak
        
        the same language
        
        as everyone else's.
        
        Nine tests.
        
        One vocabulary.
        
        One base model.
        
        If the tests pass,
        
        you and the platform
        
        now agree
        
        on what words mean.
        
        That agreement
        
        is the entire point
        
        of Agent 10.
        
        Now go build
        
        your first model.
        
        And when it fails —
        
        and it will fail —
        
        read the error.
        
        The contract
        
        is not rejecting you.
        
        It is teaching you.
        
        — Chewbacca
        Chief Wookiee Architect
        Onboarding & Environment Provisioning
        Porg Sushi Welcome Committee
