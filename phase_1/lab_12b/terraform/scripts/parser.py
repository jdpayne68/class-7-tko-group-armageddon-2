#!/usr/bin/env python3

import re
import json

# ============================================================
# Markdown Parser for Email (REFINED)
# ============================================================

def parse_markdown_to_email(text: str) -> str:
    """
    Parse markdown text into a well-formatted email with proper line breaks.
    Handles headings, bullet points, checkboxes, and bold/italic text.
    """
    if not text:
        return "No summary available."

    lines = text.split('\n')
    parsed_lines = []
    in_list = False
    list_counter = 0
    
    for i, line in enumerate(lines):
        line = line.rstrip()
        
        # Skip empty lines but track for spacing
        if not line:
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            continue
        
        # --- Handle Separators ---
        if re.match(r'^---$', line) or re.match(r'^---+$', line):
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append('-' * 50)
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Handle H1 Headings (# Heading) ---
        h1_match = re.match(r'^#\s+(.+)$', line)
        if h1_match:
            content = h1_match.group(1).strip()
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append('=' * 60)
            parsed_lines.append(content.upper())
            parsed_lines.append('=' * 60)
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Handle H2 Headings (## Heading) ---
        h2_match = re.match(r'^##\s+(.+)$', line)
        if h2_match:
            content = h2_match.group(1).strip()
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append('-' * 50)
            parsed_lines.append(content.upper())
            parsed_lines.append('-' * 50)
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Handle H3 Headings (### Heading) ---
        h3_match = re.match(r'^###\s+(.+)$', line)
        if h3_match:
            content = h3_match.group(1).strip()
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append(f'--- {content.upper()} ---')
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Handle Bold Text (**bold**) ---
        line = re.sub(r'\*\*(.+?)\*\*', r'*\1*', line)
        
        # --- Handle Italic Text (*italic*) ---
        line = re.sub(r'\*(.+?)\*', r'_\1_', line)
        
        # --- Handle Inline Code (`code`) ---
        line = re.sub(r'`([^`]+)`', r'"\1"', line)
        
        # --- Handle Checkbox Items (- [ ] item) ---
        checkbox_match = re.match(r'^-\s+\[([ x])\]\s+(.+)$', line, re.IGNORECASE)
        if checkbox_match:
            status = checkbox_match.group(1).strip()
            content = checkbox_match.group(2).strip()
            
            # Check if it's a numbered item within the checkbox
            number_match = re.match(r'^(\d+)\.\s+(.+)$', content)
            if number_match:
                num = number_match.group(1)
                item = number_match.group(2)
                if status.lower() == 'x':
                    parsed_lines.append(f'  ☑  {num}. {item}')
                else:
                    parsed_lines.append(f'  ☐  {num}. {item}')
            else:
                if status.lower() == 'x':
                    parsed_lines.append(f'  ☑  {content}')
                else:
                    parsed_lines.append(f'  ☐  {content}')
            
            in_list = True
            continue
        
        # --- Handle Bullet Points (- item) ---
        bullet_match = re.match(r'^[-*]\s+(.+)$', line)
        if bullet_match:
            content = bullet_match.group(1).strip()
            
            # Check if it's a numbered style item
            number_match = re.match(r'^(\d+)\.\s+(.+)$', content)
            if number_match:
                num = number_match.group(1)
                item = number_match.group(2)
                parsed_lines.append(f'  {num}. {item}')
            else:
                parsed_lines.append(f'  • {content}')
            
            in_list = True
            continue
        
        # --- Handle numbered items without bullet (1. item) ---
        number_match = re.match(r'^(\d+)\.\s+(.+)$', line)
        if number_match:
            num = number_match.group(1)
            content = number_match.group(2)
            parsed_lines.append(f'  {num}. {content}')
            in_list = True
            continue
        
        # --- Handle "**1. Validate..." style bold numbered items ---
        bold_number_match = re.match(r'^\*\*(\d+)\.\s+(.+?)\*\*$', line)
        if bold_number_match:
            num = bold_number_match.group(1)
            content = bold_number_match.group(2)
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append(f'  {num}. {content}')
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Handle bold text that's a section header like "**Log Enrichment**" ---
        bold_section_match = re.match(r'^\*\*(.+?)\*\*$', line)
        if bold_section_match:
            content = bold_section_match.group(1)
            if parsed_lines and parsed_lines[-1] != '':
                parsed_lines.append('')
            parsed_lines.append(f'--- {content.upper()} ---')
            parsed_lines.append('')
            in_list = False
            continue
        
        # --- Regular text ---
        if in_list and not re.match(r'^[\s]*[•☐☑-]', line):
            in_list = False
        
        parsed_lines.append(line)
    
    # Clean up multiple blank lines
    result = '\n'.join(parsed_lines)
    result = re.sub(r'\n{4,}', '\n\n\n', result)
    result = re.sub(r'\n{3,}', '\n\n', result)
    
    return result.strip()


def format_analyst_summary_for_email(summary_text: str) -> str:
    """
    Format the analyst summary for improved email readability.
    This handles the case where the summary might contain markdown or plain text.
    """
    if not summary_text:
        return "No summary available."
    
    # Clean up unicode characters
    summary_text = summary_text.replace('\u2014', '—')
    summary_text = summary_text.replace('\u201c', '"')
    summary_text = summary_text.replace('\u201d', '"')
    summary_text = summary_text.replace('\u2018', "'")
    summary_text = summary_text.replace('\u2019', "'")
    
    # Parse the markdown
    parsed = parse_markdown_to_email(summary_text)
    
    return parsed


def extract_markdown_from_email(email_content: str) -> str:
    """
    Extract the markdown content from the analyst_summary field in the email.
    """
    # Look for the analyst_summary field in the JSON payload
    json_match = re.search(r'"analyst_summary":\s*"([^"]*)"', email_content, re.DOTALL)
    if json_match:
        # Extract and unescape the markdown content
        markdown = json_match.group(1)
        # Handle escaped newlines and quotes
        markdown = markdown.replace('\\n', '\n')
        markdown = markdown.replace('\\"', '"')
        markdown = markdown.replace('\\u2014', '—')
        markdown = markdown.replace('\\u201c', '"')
        markdown = markdown.replace('\\u201d', '"')
        markdown = markdown.replace('\\u2018', "'")
        markdown = markdown.replace('\\u2019', "'")
        return markdown
    
    # If no JSON payload found, try to find markdown directly
    # Look for content between "ANALYST SUMMARY" and "JSON PAYLOAD"
    summary_match = re.search(r'ANALYST SUMMARY\s*[-]+\s*(.+?)\s*[-]+\s*JSON PAYLOAD', email_content, re.DOTALL)
    if summary_match:
        return summary_match.group(1).strip()
    
    return email_content


# ============================================================
# SAMPLE EMAIL CONTENT (from the email you received)
# ============================================================

SAMPLE_EMAIL = """======================================================================
                       WAF SECURITY INCIDENT                         
======================================================================

INCIDENT: INC-043e181e-bed4-45e2-8fe0-0867c8bf7615
FINDING:  043e181e-bed4-45e2-8fe0-0867c8bf7615
SEVERITY: MEDIUM
RISK:     35/100
PLAYBOOK: NOTIFY_ANALYST

SOURCE IP:  73.166.82.125
TARGET:     /prod
EVENTS:     76

HUMAN REVIEW REQUIRED: YES
CONTAINMENT PERFORMED: NO

----------------------------------------------------------------------
ANALYST SUMMARY
----------------------------------------------------------------------

Incident Response: Finding 043e181e-bed4-45e2-8fe0-0867c8bf7615 -------------------------------------------------- Incident Title: Repeated WAF Common Rule Set Violations from Single Source IP Against /prod Endpoint -------------------------------------------------- SOC Alert: 1. Finding ID: 043e181e-bed4-45e2-8fe0-0867c8bf7615 2. Severity: MEDIUM | Risk Score: 35/100 3. Detected: 2026-07-31T02:27:25 UTC 4. Source IP: 73.166.82.125 (Geolocation: US — not independently verified) 5. Target URI: /prod 6. Event Count: 76 requests | Block Rate: 100% (0 requests allowed) 7. Active Window: 01:57–02:23 UTC (~25.5 minutes) | Approx. Rate: ~3 requests/minute 8. WAF Rule Triggered: AWSManagedRulesCommonRuleSet (sole rule type; specific sub-rule not identified) 9. Playbook: NOTIFY_ANALYST — Human review required -------------------------------------------------- Manager Summary: Over a ~26-minute window, a single source IP (73.166.82.125) sent 76 requests to the /prod URI, all of which were blocked by the AWS WAF Common Rule Set. No requests bypassed WAF controls, and there is no evidence of successful access or exploitation. The pattern — single source, single target, consistent rule violations at a low-to-moderate rate — is consistent with automated scanning, fuzzing, or scripted probing activity. However, the specific nature of the requests cannot be confirmed from WAF metadata alone, as the AWSManagedRulesCommonRuleSet covers a broad range of violation types including SQLi, XSS, malformed inputs, and known bad user agents. Severity is bounded at MEDIUM. The primary risk drivers are request volume and the focused targeting of a single endpoint. The 100% block rate and absence of corroborating indicators from threat intelligence or application logs prevent escalation to HIGH at this time. A human analyst must review this finding before any response action is taken. -------------------------------------------------- Analyst Investigation Checklist: 1. Characterize the Source IP ☐ Query available threat intelligence feeds for 73.166.82.125 — determine whether it appears on known scanner, proxy, or abuse lists ☐ Verify geolocation independently; WAF-reported US origin is not confirmed ☐ Check whether this IP has appeared in prior findings or incidents within your environment 2. Identify the Specific WAF Sub-Rule(s) Triggered ☐ Pull detailed WAF logs for finding window (01:57–02:23 UTC) and identify which sub-rules within AWSManagedRulesCommonRuleSet fired (e.g., SQLi, XSS, SizeRestrictions, KnownBadInputs) ☐ Determine whether a single sub-rule dominated or multiple sub-rules were triggered across the 76 events 3. Assess the /prod Endpoint ☐ Confirm the function of /prod — is it an API gateway, authentication endpoint, application root, or other service? ☐ Verify whether /prod is publicly intended to be accessible or represents an exposed internal path ☐ Review application logs for the same time window to determine whether any requests reached the application layer 4. Review Request Characteristics ☐ Examine User-Agent strings, HTTP methods, and payload patterns in WAF logs for the 76 events ☐ Assess whether the request pattern is consistent with known scanning tools (e.g., Nikto, sqlmap, Burp Suite) or a misconfigured legitimate client ☐ Confirm whether the ~3 requests

----------------------------------------------------------------------
JSON PAYLOAD
----------------------------------------------------------------------
{
 "incident_id": "INC-043e181e-bed4-45e2-8fe0-0867c8bf7615",
 "finding_id": "043e181e-bed4-45e2-8fe0-0867c8bf7615",
 "severity": "MEDIUM",
 "risk_score": 35,
 "playbook": "NOTIFY_ANALYST",
 "source_ip": "73.166.82.125",
 "target": "/prod",
 "event_count": 76,
 "human_review_required": true,
 "containment_performed": false,
 "analyst_summary": "# Incident Response: Finding 043e181e-bed4-45e2-8fe0-0867c8bf7615\n\n---\n\n## Incident Title:\nRepeated WAF Common Rule Set Violations from Single Source IP Against `/prod` Endpoint\n\n---\n\n## SOC Alert:\n- **Finding ID:** 043e181e-bed4-45e2-8fe0-0867c8bf7615\n- **Severity:** MEDIUM | **Risk Score:** 35/100\n- **Detected:** 2026-07-31T02:27:25 UTC\n- **Source IP:** 73.166.82.125 (Geolocation: US \u2014 not independently verified)\n- **Target URI:** `/prod`\n- **Event Count:** 76 requests | **Block Rate:** 100% (0 requests allowed)\n- **Active Window:** 01:57\u201302:23 UTC (~25.5 minutes) | **Approx. Rate:** ~3 requests/minute\n- **WAF Rule Triggered:** AWSManagedRulesCommonRuleSet (sole rule type; specific sub-rule not identified)\n- **Playbook:** NOTIFY_ANALYST \u2014 Human review required\n\n---\n\n## Manager Summary:\nOver a ~26-minute window, a single source IP (73.166.82.125) sent 76 requests to the `/prod` URI, all of which were blocked by the AWS WAF Common Rule Set. No requests bypassed WAF controls, and there is no evidence of successful access or exploitation.\n\nThe pattern \u2014 single source, single target, consistent rule violations at a low-to-moderate rate \u2014 is consistent with automated scanning, fuzzing, or scripted probing activity. However, the specific nature of the requests cannot be confirmed from WAF metadata alone, as the AWSManagedRulesCommonRuleSet covers a broad range of violation types including SQLi, XSS, malformed inputs, and known bad user agents.\n\nSeverity is bounded at MEDIUM. The primary risk drivers are request volume and the focused targeting of a single endpoint. The 100% block rate and absence of corroborating indicators from threat intelligence or application logs prevent escalation to HIGH at this time. A human analyst must review this finding before any response action is taken.\n\n---\n\n## Analyst Investigation Checklist:\n\n**1. Characterize the Source IP**\n- [ ] Query available threat intelligence feeds for 73.166.82.125 \u2014 determine whether it appears on known scanner, proxy, or abuse lists\n- [ ] Verify geolocation independently; WAF-reported US origin is not confirmed\n- [ ] Check whether this IP has appeared in prior findings or incidents within your environment\n\n**2. Identify the Specific WAF Sub-Rule(s) Triggered**\n- [ ] Pull detailed WAF logs for finding window (01:57\u201302:23 UTC) and identify which sub-rules within AWSManagedRulesCommonRuleSet fired (e.g., SQLi, XSS, SizeRestrictions, KnownBadInputs)\n- [ ] Determine whether a single sub-rule dominated or multiple sub-rules were triggered across the 76 events\n\n**3. Assess the `/prod` Endpoint**\n- [ ] Confirm the function of `/prod` \u2014 is it an API gateway, authentication endpoint, application root, or other service?\n- [ ] Verify whether `/prod` is publicly intended to be accessible or represents an exposed internal path\n- [ ] Review application logs for the same time window to determine whether any requests reached the application layer\n\n**4. Review Request Characteristics**\n- [ ] Examine User-Agent strings, HTTP methods, and payload patterns in WAF logs for the 76 events\n- [ ] Assess whether the request pattern is consistent with known scanning tools (e.g., Nikto, sqlmap, Burp Suite) or a misconfigured legitimate client\n- [ ] Confirm whether the ~3 requests"
}

======================================================================"""


# ============================================================
# TEST FUNCTION
# ============================================================

def test_parser():
    """Test the markdown parser with the sample email content."""
    
    print("=" * 70)
    print("TESTING MARKDOWN PARSER")
    print("=" * 70)
    print()
    
    print("📥 Extracting markdown from email...")
    print("-" * 50)
    
    # Extract the markdown content
    markdown_content = extract_markdown_from_email(SAMPLE_EMAIL)
    
    print(f"✅ Extracted {len(markdown_content)} characters of markdown")
    print()
    print("📤 PARSED OUTPUT:")
    print("=" * 70)
    print()
    
    # Parse the markdown
    parsed = format_analyst_summary_for_email(markdown_content)
    print(parsed)
    
    print()
    print("=" * 70)
    print("TEST COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    test_parser()