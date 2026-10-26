# 🔑 Instructor Answer Key – Day 2: Stocking Fillers (Developer, Challenge)

> Not part of the learner guide. Use it to test the lab end to end. Run in Cloud Shell after **Prepare Hollyfield** succeeds.

## Hollyfield toolkit

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-central1
export BENCH=$(gcloud storage buckets list --format='value(name)' --filter='name~^hollyfield-workbench-')
export API_URL=$(gcloud run services describe hollyfield-core-banking --region $REGION --format 'value(status.url)')
python3 -m venv ~/holly-venv && source ~/holly-venv/bin/activate
pip install --quiet --upgrade google-adk google-cloud-logging requests
```

## Challenge 2 – Meet the Core-Banking API

```bash
curl -s "$API_URL/v1/savings/rates" | jq
curl -s "$API_URL/v1/accounts/HB-10234/balance" | jq
curl -s -w '\nHTTP %{http_code}\n' "$API_URL/v1/accounts/HB-99999/balance"   # 404 ACCOUNT_NOT_FOUND
curl -s -w '\nHTTP %{http_code}\n' "$API_URL/v1/accounts/12345/balance"      # 400 INVALID_ACCOUNT_ID
# wait 1 minute, then Validate
```

Answers: HB-10234 = Christmas Saver, £812.40 · Christmas Saver = 4.10 % AER, variable · unknown account = HTTP 404 `ACCOUNT_NOT_FOUND` · `12345` = HTTP 400 `INVALID_ACCOUNT_ID`.

## Challenge 3 – Stocking Fillers

```bash
REPO=https://raw.githubusercontent.com/syeda-spektra/FastlaneGCP/refs/heads/main/Day-02-Stocking-Fillers
mkdir -p ~/holly
curl -fsSL $REPO/solution/agent.py -o ~/holly/agent.py          # completed version of the starter (includes the bonus tool)
curl -fsSL $REPO/starter/__init__.py -o ~/holly/__init__.py
curl -fsSL $REPO/starter/requirements.txt -o ~/holly/requirements.txt
printf "GOOGLE_GENAI_USE_VERTEXAI=TRUE\nGOOGLE_CLOUD_PROJECT=%s\nGOOGLE_CLOUD_LOCATION=%s\nCORE_BANKING_URL=%s\n" "$PROJECT_ID" "$REGION" "$API_URL" > ~/holly/.env

cd ~ && nohup adk api_server --port 8000 > /tmp/adk-local.log 2>&1 & sleep 15
ask() { local s="s$RANDOM"; curl -s -X POST "http://localhost:8000/apps/holly/users/elf/sessions/$s" -H "Content-Type: application/json" -d '{}' >/dev/null
  curl -s -X POST "http://localhost:8000/run" -H "Content-Type: application/json" -d "{\"app_name\":\"holly\",\"user_id\":\"elf\",\"session_id\":\"$s\",\"new_message\":{\"role\":\"user\",\"parts\":[{\"text\":\"$1\"}]}}" \
  | jq -r '.[] | .content.parts[]? | if .functionCall then "TOOL CALL : \(.functionCall.name) \(.functionCall.args|tostring)" elif .text then "HOLLY     : \(.text)" else empty end'; }
ask "What's the balance of my Christmas Saver, account HB-10234?"
ask "What rate does the Christmas Saver pay?"
ask "For HB-10234, what's my balance and what rate am I getting?"
# wait 1 minute, then Validate
```

## Challenge 4 – Account Not Found

```bash
ask "What's the balance on account HB-99999?"
# Expected: TOOL CALL get_account_balance {"account_id":"HB-99999"} -> Holly apologises, asks to check the number, no amount
# wait 1 minute, then Validate
```

## Challenge 5 – Wrap the Gift

```bash
gcloud storage cp ~/holly/agent.py ~/holly/__init__.py ~/holly/requirements.txt gs://$BENCH/app/holly/
```

## Christmas Bonus

```bash
ask "How much interest will HB-10234 earn by New Year?"
pkill -f "adk api_server --port 8000"
# wait 1 minute, then Validate
```

## What learners see in the trace

```bash
gcloud logging read 'logName:holly-trace' --freshness 1h --limit 20 \
  --format="table(timestamp,jsonPayload.message,jsonPayload.tool,jsonPayload.args.account_id,jsonPayload.status,jsonPayload.error_code)"
```
