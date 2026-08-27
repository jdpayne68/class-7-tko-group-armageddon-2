
# Agent 10 — Domain Model Architecture Playbook

> **Purpose:** This playbook defines how students and engineers should develop, test, integrate, and troubleshoot the Agent 10 domain-model architecture.

---

# 1. Mission

Agent 10 provides the shared domain contracts used throughout Gen2X.

Its responsibility is to ensure that operational agents communicate using consistent, validated, understandable structures.

The basic rule is:

```text
ENUMS
    define vocabulary

MODELS
    define contracts

AGENTS
    perform work
```

Agent 10 should make the rest of the system easier to reason about.

If an operational agent must guess what another agent means, the contract is incomplete.

---

# 2. Current Structure

```text
models/
│
├── __init__.py
├── base_model.py
│
├── enums/
│   │
│   ├── __init__.py
│   ├── base_enum.py
│   │
│   ├── indicator_enums.py
│   ├── provider_enums.py
│   ├── threat_enums.py
│   ├── report_enums.py
│   ├── response_enums.py
│   ├── cache_enums.py
│   └── platform_enums.py
│
├── indicator.py
├── provider.py
├── evidence.py
├── threat.py
├── response.py
└── report.py
```

---

# 3. Operational Flow

The current domain flow is:

```text
Provider
    │
    ▼
Evidence
    │
    ▼
Evidence Aggregation
    │
    ▼
Fusion / Assessment
    │
    ▼
Threat
    │
    ▼
Response
    │
    ▼
Report
```

Each layer has a different responsibility.

```text
Provider
    Where did the information come from?

Evidence
    What was observed?

Aggregation
    What evidence exists together?

Fusion
    What does the evidence mean?

Threat
    What do we currently believe?

Response
    What should we do?
    Are we authorized?

Report
    What must humans know?
    Who is accountable?
```

Do not casually combine these responsibilities.

---

# 4. Before Writing Code

Before creating or modifying a model, answer five questions:

```text
1. What does this object represent?

2. Who creates it?

3. Who consumes it?

4. What should it validate?

5. What should it NOT decide?
```

If those answers are unclear, stop and examine the architecture before adding code.

A new class should exist because it represents a meaningful domain concept.

Not because adding another class looked entertaining at 1:00 AM.

---

# 5. Step One — Check the Vocabulary

Before adding a string field representing a controlled security concept, check:

```text
models/enums/
```

Ask:

```text
Does an enum already represent this concept?
```

Prefer:

```python
severity: ThreatSeverity
```

over:

```python
severity: str
```

when the possible values belong to a controlled vocabulary.

---

# 6. Do Not Duplicate Enums

Before creating:

```python
class NewSeverity(...)
```

search the existing enum layer.

The project should not develop:

```text
ThreatSeverity
SecuritySeverity
FindingSeverity
IncidentSeverity
SeverityLevel
SeverityRating
```

when they all represent the same concept.

Different names should represent genuinely different concepts.

---

# 7. Step Two — Select the Correct Model

Ask which domain owns the concept.

```text
indicator.py
    What are we investigating?

provider.py
    Where did the information come from?

evidence.py
    What was observed?

threat.py
    What do we believe?

response.py
    What should we do?
    Are we authorized?

report.py
    What should humans know?
    Who is accountable?
```

Put behavior as close as practical to the concept that owns it.

---

# 8. Step Three — Define the Contract

Start with the data contract.

Example:

```python
class ThreatSummary(BaseModel):

    title: str

    summary: str

    condition: ThreatCondition

    severity: ThreatSeverity

    confidence: ThreatConfidence
```

Before adding methods, make sure the fields make sense.

Ask:

```text
Which fields are required?

Which fields are optional?

Which values are controlled?

Which collections may be empty?

Which values can legitimately be unknown?
```

---

# 9. Unknown Is a Valid State

Security data is frequently incomplete.

Do not invent information simply to satisfy a model.

Prefer:

```python
approved_by: str | None = None
```

when approval attribution may legitimately be unknown.

Do not replace missing information with:

```python
approved_by = "security_team"
```

unless the system actually knows that.

The rule is:

> **Unknown is better than fabricated.**

---

# 10. Step Four — Add Validation

Validation should protect the model from malformed state.

Examples:

```text
Empty required identifiers
Invalid enum values
Negative counters
Malformed collections
Unexpected fields
Whitespace-only required text
```

Example:

```python
@field_validator("threat_id")
@classmethod
def validate_threat_id(
    cls,
    value: str,
) -> str:

    value = value.strip()

    if not value:
        raise ValueError(
            "threat_id cannot be empty."
        )

    return value
```

Validation should fail clearly.

---

# 11. Validation Is Not Analysis

Do not turn Pydantic validators into hidden security engines.

Avoid designs such as:

```python
@field_validator("severity")
def determine_threat_severity(...):
    ...
```

Threat analysis belongs in the appropriate analysis layer.

The model should validate the resulting state.

Remember:

```text
MODEL
    represents state

VALIDATOR
    protects structure

AGENT / SERVICE
    performs reasoning
```

---

# 12. Step Five — Normalize Carefully

External data may contain unnecessary formatting differences.

For example:

```text
" GitHub "
"github"
"GITHUB"
```

Depending on the field, normalization may be appropriate.

Typical normalization includes:

```python
value = value.strip()
```

and converting empty optional values to:

```python
None
```

Normalization should make equivalent representations consistent.

It should not silently change meaning.

---

# 13. Step Six — Add Derived Properties

If a value can be reliably calculated from existing state, consider deriving it instead of storing it.

Prefer:

```python
@property
def evidence_count(self) -> int:
    return len(self.evidence_ids)
```

over maintaining:

```python
evidence_count: int
evidence_ids: list[str]
```

independently.

Otherwise this becomes possible:

```text
evidence_count = 12

len(evidence_ids) = 9
```

Now which value is correct?

Derived values reduce opportunities for disagreement.

---

# 14. Do Not Derive Analytical Conclusions Accidentally

Derived state is appropriate when the answer follows directly from stored data.

For example:

```python
@property
def has_evidence(self) -> bool:
    return bool(self.evidence_ids)
```

That is deterministic.

Be careful with:

```python
@property
def is_corroborated(self) -> bool:
    return self.provider_count > 1
```

Multiple providers do not necessarily represent independent corroboration.

Therefore:

```text
provider_count
    may be derived

corroborated
    may require analysis
```

Know the difference.

---

# 15. Step Seven — Add Small Domain Helpers

Small methods can improve usability.

Examples:

```python
add_provider()
add_evidence_id()
add_note()
get_finding()
matches_threat()
describe()
```

These should make common operations safer or clearer.

They should not transform a model into an entire service layer.

---

# 16. `describe()` Is for Humans

A `describe()` method should provide a concise representation useful for:

```text
Debugging
Logs
CLI output
Testing
Developer inspection
```

Example:

```python
def describe(self) -> str:

    return (
        f"{self.title} "
        f"[severity={self.severity.value}, "
        f"confidence={self.confidence.value}]"
    )
```

Do not turn `describe()` into a complete report generator.

---

# 17. Step Eight — Test Construction

First test the happy path.

Example:

```python
summary = ThreatSummary(
    title="Exposed Credential",
    summary="A credential was discovered in a public repository.",
    condition=ThreatCondition.EXPOSED_CREDENTIAL,
    severity=ThreatSeverity.CRITICAL,
    confidence=ThreatConfidence.HIGH,
)
```

Confirm:

```text
Does it instantiate?

Are enums accepted?

Are defaults correct?

Are timestamps correct?

Are generated identifiers present?
```

---

# 18. Step Nine — Test Failure

Do not only test valid data.

Try to break the model.

Examples:

```text
Missing required fields
Empty identifiers
Whitespace-only text
Invalid enum values
Negative values
Duplicate entries
Unexpected fields
None where None is prohibited
```

A useful model should fail predictably.

---

# 19. Test the Boundary, Not Just the Center

If a field allows:

```python
Field(
    ge=0,
    le=100,
)
```

test:

```text
-1
0
1
99
100
101
```

Boundary testing often reveals mistakes faster than normal values.

---

# 20. Step Ten — Test Mutation

If the model permits assignment, test it.

For example:

```python
model.severity = ThreatSeverity.HIGH
```

Then attempt invalid mutation.

If:

```python
validate_assignment=True
```

is configured, verify that assignment behaves as expected.

Do not assume configuration works because it looks correct.

Run it.

---

# 21. Step Eleven — Test Serialization

Models will eventually cross boundaries.

Test:

```python
model.model_dump()
```

and:

```python
model.model_dump(
    mode="json"
)
```

Check:

```text
Enums
UUIDs
Datetimes
Nested models
Optional fields
Lists
Dictionaries
```

The serialized representation should be understandable and predictable.

---

# 22. Step Twelve — Test Composition

Individual models may work perfectly while integration fails.

For example:

```text
ThreatSummary
    works

ResponseSummary
    works

ReportIdentity
    works

ReportAccountability
    works
```

Then:

```python
Report(...)
```

fails.

That is normal.

Composition tests reveal:

```text
Type mismatches
Enum mismatches
Identifier mismatches
Missing fields
Import problems
Serialization problems
Unexpected assumptions
```

---

# 23. Recommended Testing Order

When testing Agent 10, work from the bottom upward.

```text
1. Base enums

2. Domain enums

3. Base model

4. Provider

5. Indicator

6. Evidence

7. Threat

8. Response

9. Report

10. Cross-model integration
```

Do not begin by testing the largest composed object if its dependencies have not been validated.

---

# 24. When VS Code Shows Red

Do not panic.

Read the error.

Common problems include:

```text
Import path mismatch
Missing enum
Wrong enum member
Incorrect field type
Missing required field
Invalid Optional usage
Pydantic validation error
Circular import
Incorrect method name
Serialization mismatch
```

Start with the smallest failure.

---

# 25. Debugging Sequence

Use this sequence:

```text
ERROR
  │
  ▼
Read the complete message
  │
  ▼
Identify the file
  │
  ▼
Identify the line
  │
  ▼
Identify the model
  │
  ▼
Identify the field or import
  │
  ▼
Check the enum/model definition
  │
  ▼
Fix one problem
  │
  ▼
Run again
```

Do not respond to ten red lines by changing ten unrelated files simultaneously.

One error may be causing the other nine.

---

# 26. Imports

As the architecture grows, imports become important.

The intended dependency direction should remain understandable.

Conceptually:

```text
base_enum
    ↓
domain enums
    ↓
base_model
    ↓
domain models
    ↓
agents/services
```

Be cautious when two model modules begin importing large portions of each other.

That may indicate a circular dependency or confused ownership.

---

# 27. Circular Imports Are Architectural Clues

Suppose:

```text
threat.py
    imports response.py
```

while:

```text
response.py
    imports threat.py
```

Python may complain.

But the more important question is:

> Why do these two domain objects require each other's complete definitions?

Sometimes the fix is technical.

Sometimes the circular import is exposing an architectural problem.

Do not automatically hide it.

Investigate it.

---

# 28. Agent Integration Rule

Operational agents should return known domain models whenever practical.

Prefer:

```python
return ThreatEvidence(...)
```

over:

```python
return {
    "thing": "...",
    "stuff": "...",
    "maybe_severity": "...",
}
```

Dictionaries are useful.

But arbitrary dictionaries do not establish a clear contract.

Structured boundaries make integrations easier to understand.

---

# 29. Provider Integration Playbook

When adding a provider agent:

```text
STEP 1
    Collect provider-native data.

STEP 2
    Preserve raw source information when required.

STEP 3
    Normalize appropriate fields.

STEP 4
    Map provider concepts into Gen2X enums.

STEP 5
    Construct the appropriate evidence model.

STEP 6
    Validate.

STEP 7
    Submit evidence to aggregation/fusion.
```

Conceptually:

```text
GitHub Native Data
        │
        ▼
Provider Adapter
        │
        ▼
Gen2X ThreatEvidence
        │
        ▼
EvidenceAggregator
```

The provider adapter translates.

The domain model establishes the contract.

---

# 30. Do Not Throw Away Provider Context

Normalization should not destroy useful provenance.

If GitHub calls something:

```text
repository
```

and another platform calls something:

```text
project
```

Gen2X may normalize those concepts for analysis.

But preserve enough source context to understand where the observation originated.

Security evidence without provenance becomes much less useful.

---

# 31. Threat Integration Playbook

Threat creation should follow analysis.

```text
Evidence
    │
    ▼
Aggregation
    │
    ▼
Fusion
    │
    ▼
Assessment
    │
    ▼
Threat
```

Do not make `Threat` responsible for gathering all its own evidence.

Do not make `Threat` secretly perform Fusion.

`Threat` represents the resulting domain state.

---

# 32. Response Integration Playbook

Response begins after a threat conclusion exists.

```text
Threat
    │
    ▼
Recommendation
    │
    ▼
Investigation State
    │
    ▼
Governance
    │
    ▼
Authorization
```

Remember:

```text
Recommendation
    ≠
Authorization
```

and:

```text
Authorization
    ≠
Execution
```

The response model should not bypass these boundaries.

---

# 33. Report Integration Playbook

Reporting should consume established domain state.

```text
Threat ───────────────┐
                      │
Response ─────────────┤
                      │
Evidence ─────────────┤
                      │
Governance ───────────┤
                      ▼
                   Report
```

The report communicates.

It should not silently recalculate the underlying threat.

---

# 34. Executive Summary Rule

The executive summary should answer:

```text
What happened?

How serious is it?

What is affected?

What are we doing?

Do you need a decision from me?
```

Then stop.

If the executive summary requires twelve pages, it is no longer an executive summary.

---

# 35. Reporting Must Preserve Facts

Different audiences may receive different levels of detail.

```text
Executive
    concise

SOC Analyst
    technical

Engineer
    implementation-oriented

Auditor
    provenance and accountability
```

But:

```text
Different Presentation
        ≠
Different Facts
```

Never adjust severity, confidence, or conclusions merely because the audience changed.

---

# 36. Report Finalization Playbook

The report lifecycle is:

```text
DRAFT
   │
   ▼
REVIEW
   │
   ▼
FINAL
   │
   ▼
ARCHIVED
```

During `DRAFT`:

```text
Add findings
Edit summaries
Add notes
Correct errors
```

During `REVIEW`:

```text
Validate facts
Check attribution
Check evidence references
Check recommendations
Check approval state
Correct problems
```

Once `FINAL`:

```text
STOP ORDINARY MUTATION
```

The report is now a historical artifact.

---

# 37. Correcting a Final Report

If a material error is discovered:

```text
DO NOT
    silently modify the final report
```

Instead:

```text
Original Report
      │
      ▼
Correction Required
      │
      ▼
New / Revised Report
```

Preserve:

```text
Original conclusion
Original evidence
Original timestamp
Original accountability
```

Then record the correction separately.

---

# 38. Before Finalizing a Report

Check:

```text
[ ] Report identity exists

[ ] Threat reference exists

[ ] Executive summary is accurate

[ ] Threat summary matches threat state

[ ] Response summary matches response state

[ ] Evidence references are present

[ ] Provider information is present

[ ] Findings are complete

[ ] Accountability is recorded

[ ] Approval information is accurate

[ ] Unknown values remain honestly unknown

[ ] Analyst notes are appropriate

[ ] Report has been reviewed
```

Only then finalize.

---

# 39. Trust Playbook

When consuming information, ask:

```text
Who produced it?

How was it obtained?

Can the source be identified?

Can the observation be correlated?

Is the source independent?

Is the information current?

Has it been normalized?

Has anything been lost during translation?
```

Do not confuse:

```text
VALID
```

with:

```text
TRUSTED
```

---

# 40. Confidence Playbook

Confidence describes how strongly available evidence supports a conclusion.

Ask:

```text
How much evidence exists?

How reliable are the sources?

Are the sources independent?

Do observations agree?

Are conflicts present?

Is important evidence missing?

How recent is the evidence?
```

Confidence should reflect evidence quality.

Not enthusiasm.

---

# 41. Authority Playbook

Before any consequential response:

```text
What action is proposed?

Who or what can perform it?

Who is permitted to authorize it?

Is approval required?

Has approval actually occurred?

What scope was approved?

Is the authorization still valid?
```

Remember:

```text
I CAN
    does not mean

I MAY
```

---

# 42. Accountability Playbook

For consequential decisions, preserve:

```text
Who investigated?

Who recommended?

Who approved?

Who rejected?

Why?

When?

What evidence was available?

What report recorded the decision?
```

If something is unknown:

```text
record unknown
```

Do not invent attribution.

---

# 43. Change Discipline

When modifying Agent 10:

```text
1. Identify the domain concept.

2. Check existing enums.

3. Check existing models.

4. Avoid duplication.

5. Make the smallest coherent change.

6. Test the changed model.

7. Test dependent models.

8. Test serialization.

9. Test integration.

10. Update documentation if the contract changed.
```

Small changes are easier to reason about.

---

# 44. When to Modify an Existing Model

Modify an existing model when:

```text
The concept already belongs there.

The new field is part of the same responsibility.

The change does not blur a domain boundary.
```

Example:

```text
Evidence gains observation_key
```

That belongs naturally to evidence identity/correlation.

---

# 45. When to Create a New Model

Consider a new model when:

```text
A concept has its own responsibility.

Several fields always travel together.

The concept has its own validation.

The concept has its own lifecycle.

Separating it makes the parent easier to understand.
```

For example:

```text
ResponseGovernance
```

deserves its own model because authorization is a distinct concern.

---

# 46. When NOT to Create a New Model

Do not create a model merely because:

```text
A class can be created.

The file looks too short.

One field feels lonely.

You want another abstraction.

It might someday be useful.
```

Every abstraction creates maintenance cost.

Make it earn its existence.

---

# 47. Failure Is Useful

When a model fails validation during development, that is not necessarily a bad result.

It may mean the contract is doing its job.

A useful failure says:

```text
"This state is not allowed."
```

The engineer then asks:

```text
Is the input wrong?

Or is the contract wrong?
```

Either answer teaches us something.

---

# 48. Student Testing Rule

Do not change the model immediately because one test fails.

First determine:

```text
Is the implementation wrong?

Is the test wrong?

Is the enum wrong?

Is the assumption wrong?

Is the architecture wrong?
```

Then change the correct thing.

A passing test that validates the wrong architecture is not success.

---

# 49. Recommended Student Workflow

For each model:

```text
READ
    Understand its responsibility.

TRACE
    Identify its enums and dependencies.

INSTANTIATE
    Create a valid example.

BREAK
    Feed it invalid data.

MUTATE
    Test allowed changes.

SERIALIZE
    Inspect its output.

COMPOSE
    Place it inside its parent model.

INTEGRATE
    Pass it to the next layer.

EXPLAIN
    Be able to describe what it does.
```

If you cannot explain the model, keep studying it.

---

# 50. Definition of Done

An Agent 10 model is not complete merely because Python accepts it.

A reasonable definition of done is:

```text
[ ] Responsibility is clear

[ ] Fields are understandable

[ ] Existing enums are reused appropriately

[ ] Required data is validated

[ ] Unknown data can remain unknown when appropriate

[ ] Derived state is not unnecessarily duplicated

[ ] Business reasoning is not hidden in validators

[ ] Serialization works

[ ] Invalid construction has been tested

[ ] Mutation behavior has been tested

[ ] Composition has been tested

[ ] Integration has been tested

[ ] Documentation reflects the contract
```

---

# 51. Incident Troubleshooting Checklist

If Agent 10 integration fails:

```text
[ ] Check imports

[ ] Check enum names

[ ] Check enum values

[ ] Check required fields

[ ] Check Optional fields

[ ] Check UUID vs string assumptions

[ ] Check datetime handling

[ ] Check validators

[ ] Check default factories

[ ] Check nested model types

[ ] Check serialization

[ ] Check circular imports

[ ] Check whether two layers are duplicating responsibility
```

Then run the smallest relevant test again.

---

# 52. The Golden Boundaries

Keep these distinctions visible:

```text
Evidence
    ≠
Conclusion

Severity
    ≠
Confidence

Confidence
    ≠
Trust

Multiple Sources
    ≠
Corroboration

Recommendation
    ≠
Authorization

Capability
    ≠
Authority

Authorization
    ≠
Execution

Execution
    ≠
Verification

Summary
    ≠
Source of Truth

Final Report
    ≠
Editable Draft
```

Most architectural problems begin when one of these distinctions disappears.

---

# 53. Final Operational Rule

When working on Agent 10:

```text
DEFINE
    the vocabulary.

MODEL
    the state.

VALIDATE
    the contract.

PRESERVE
    provenance.

SEPARATE
    reasoning from representation.

REQUIRE
    authority before action.

RECORD
    accountability.

TEST
    the boundaries.

PRESERVE
    history.
```

Agent 10 should make operational agents safer and easier to integrate.

If Agent 10 makes every agent more complicated, examine the design.

If Agent 10 allows every agent to speak the same language while preserving clear responsibility boundaries, it is doing its job.

---

# Chewbacca's Operational Commentary 🐾

The model

does not work.

Good.

Now

we learn

why.

First:

Do not

hit

the keyboard.

The keyboard

probably

did nothing

wrong.

Probably.

Read

the error.

Find

the model.

Find

the field.

Find

the assumption.

Then ask:

"Who owns

this problem?"

If Evidence

is trying

to authorize

a response...

wrong room.

If Report

is calculating

threat severity...

wrong room.

If Response

is inventing

evidence...

wrong room.

If Pydantic

is deciding

whether GitHub

is trustworthy...

very wrong room.

Put

the responsibility

back

where it belongs.

Then test

again.

And again.

And again.

Because testing

is not

the ceremony

performed

after software

is finished.

Testing

is how

software

tells you

what you

actually built.

Sometimes

you discover

exactly

what you

intended.

Sometimes

you discover

a typo.

Sometimes

you discover

an enum

that does not

exist.

Sometimes

you discover

three classes

all believe

they are

in charge

of the same

decision.

The red line

is not

your enemy.

It is

the computer

politely saying:

"Engineer,

we need

to talk."

Listen.

Fix

one thing.

Run

again.

Preserve

the boundaries.

Preserve

the evidence.

Preserve

the authority.

Preserve

the history.

And never

change

six files

simultaneously

because

VS Code

hurt

your feelings.

That path

leads

to suffering.

And worse...

a failed

integration test

five minutes

before class.

— Chewbacca  
Chief Wookiee Architect  
Agent 10 Operations Commander  
Red-Line Incident Response Team  
Porg Sushi Test Engineering
