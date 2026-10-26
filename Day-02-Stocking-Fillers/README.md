# 🧦 12 Days of AI Agents – Day 2: Stocking Fillers (Track A: Developer, Challenge) 🎁

Fast Lane · *The Christmas Change Freeze* · Hollyfield Building Society storyline · Google Cloud · CloudLabs

Learners give **Holly** (Hollyfield's ADK customer agent) her first **function tools**. The tools call a mock **core-banking API on Cloud Run** for live balances and savings rates. Learners describe the tools so Gemini calls the right one, combine two tools in one answer, and handle an unknown account with a structured error instead of a crash or a guessed number.

| Item | Value |
|---|---|
| Duration | ~60 min (90-min launch limit) |
| Version | Challenge (goal + rules + hints). Guided version: separate package |
| Start point | Fresh starter (no dependency on Day 1) |
| Region / model | `us-central1` · Gemini 2.5 Flash on Vertex AI (`AGENT_MODEL` env var overrides) |
| Points | 94 validation + 6 questions = **100**, plus **+10** optional Christmas Bonus |
| Badge | 🎖️ Toolsmith |

## 1. Publish

1. Push the **contents** of this folder to the root of the lab repo (branch `main`).
1. Fill in the raw URLs: `./scripts/set-ids.sh <owner>/<repo>`
1. Create the CloudLabs template and validation steps (below), then fill in the step IDs:
   `./scripts/set-ids.sh <owner>/<repo> EX1=<id> EX2=<id> EX3=<id> EX4=<id> EX5=<id> EX6=<id>`
1. Commit and push again. The script lists anything still unfilled.

## 2. CloudLabs template

| Field | Value |
|---|---|
| Cloud Platform | Google Cloud Platform |
| Subscription type | Dedicated Subscription (one GCP project per learner) |
| Zones | `us-central1-a` (or `-b` / `-c`) |
| Deployment Manager template | `<raw>/deployment/deploy.yaml` |
| Parameters | `<raw>/deployment/param.yaml` |
| Lab guide (masterdoc) | `<raw>/lab-guides/Day-02-Developer-Challenge/masterdoc.json` |
| IAM (Attendee) | Basic **Editor** on the project (needs Vertex AI, Cloud Run read, Logging, Storage) |
| Approx. deployment duration | 5 min (Windows lab VM) |

The lab VM settings are the same as Day 1: VM `labvm-{GET-DEPLOYMENT-ID}`, outputs vmPublicIp / vmUsername / vmPassword / vmPrivateIp / vpcId / subnetId.

**Inject keys (deployment outputs):** `ProjectId`, `Region`, `WorkbenchBucket`, `CoreBankingService`, plus the VM outputs.

## 3. Validation steps

All steps: **PowerShellV2**, **Run As System**, parameters `DeploymentId = GET-DEPLOYMENT-ID`, `projectname = GET-GCP-PROJECT`.

| # | Step name | Script | Score | Passes when |
|:---:|---|---|:---:|---|
| EX1 | Prepare Hollyfield | `validation/LAB02A-EX1-TASK1.ps1` | 5 | APIs on, builder IAM set, core-banking API built by Cloud Build and **Ready** on Cloud Run. Safe to re-run; waits up to 150 s, then asks the learner to validate again |
| EX2 | Explore the Core-Banking API | `validation/LAB02A-EX2-TASK1.ps1` | 10 | Cloud Run request logs show rates 200, a balance 200 and an unknown-account 404 |
| EX3 | Holly Uses Her Tools | `validation/LAB02A-EX3-TASK1.ps1` | 35 | `holly-trace`: balance of HB-10234 ✔, rates ✔, both tools in **one** turn ✔, an answer quotes 4.10 % ✔ |
| EX4 | Holly Handles an Unknown Account | `validation/LAB02A-EX4-TASK1.ps1` | 25 | `holly-trace`: `ACCOUNT_NOT_FOUND` returned (no exception), and Holly's reply in that turn has no £ amount |
| EX5 | Holly's Tools Pass Code Review | `validation/LAB02A-EX5-TASK1.ps1` | 19 | `gs://<workbench>/app/holly`: both tools defined, documented and registered; `error_code` used; trace callbacks intact; no hard-coded balance |
| EX6 | Christmas Bonus: Interest by New Year | `validation/LAB02A-EX6-TASK1.ps1` | 10 (bonus) | `holly-trace`: a tool whose name contains `interest` succeeded for an HB account |

Questions: 3 × 2 points (`lab-guides/Day-02-Developer-Challenge/Inline-Questions`). If the platform can't score above 100, set EX6 to 0 points or move its 10 points into EX3.

**How validation works.** The starter's **Elf trace** registers three ADK callbacks: `after_tool_callback`, `on_tool_error_callback` and `after_model_callback`. They write every tool call (tool, args, status, error_code, invocation_id) and every final answer to the Cloud Logging log **`holly-trace`**. Validators read that log, plus the API's own Cloud Run request logs, so they check what Holly actually did rather than what the learner typed.

## 4. What gets deployed

| Resource | Name | Created by |
|---|---|---|
| VPC / subnet / RDP firewall | `clgvpc-<id>` / `clgsubnet-<id>` / `allow-rdp-<id>` | Deployment Manager |
| Workbench bucket (30-day lifecycle) | `hollyfield-workbench-<id>` | Deployment Manager |
| Builder identity | `hollyfield-builder` (run.admin, artifactregistry.writer, logging.logWriter, storage.objectViewer, actAs core-banking-sa) | DM + Prepare step |
| API runtime identity | `core-banking-sa` (no project roles) | Deployment Manager |
| Lab VM (Windows, web RDP) | `labvm-<id>` e2-standard-2 | Deployment Manager |
| Artifact Registry repo | `hollyfield` (docker, us-central1) | Prepare step |
| Cloud Run service | `hollyfield-core-banking` (0–2 instances, 256 Mi, public, synthetic data) | Prepare step → Cloud Build |

**Mock API** (`core-banking-api/`): `GET /v1/accounts/<id>/balance` (200 / 400 `INVALID_ACCOUNT_ID` / 404 `ACCOUNT_NOT_FOUND`) and `GET /v1/savings/rates[?product=]`. Accounts: HB-10234 Eleanor Frost (Christmas Saver £812.40), HB-20419 Noel Winters (Easy Access £2,450.00), HB-31877 Carol Bell (Festive Regular £600.00). Rates: Christmas Saver 4.10 % variable, Easy Access 3.25 % variable, Festive Regular 5.00 % fixed.

## 5. Approximate cost per learner launch (list prices, us-central1, to be confirmed)

| Item | Estimate |
|---|---|
| Windows lab VM e2-standard-2 (incl. Windows licence), 1.5 h | ~$0.24 |
| Cloud Build (~3 build-min, once per project) | ~$0.02 |
| Gemini 2.5 Flash (~30 model calls) | ~$0.05 |
| Cloud Run, Artifact Registry, Logging, Storage | < $0.02 |
| **Total** | **≈ $0.35 per launch** |

## 6. Folder map

```
deployment/          deploy.yaml, param.yaml (Deployment Manager)
core-banking-api/    mock API: main.py, data, Dockerfile, cloudbuild.yaml
starter/             learner starter: agent.py (TODOs + Elf trace), __init__.py, requirements.txt
solution/            answer key (incl. bonus tool)
lab-guides/          getting-started, challenge guide, knowledge check, questions, masterdoc, media
validation/          LAB02A-EX1..EX6 PowerShellV2 validators, monitor.sh (support diagnostics)
instructor/          end-to-end answer key with commands
scripts/set-ids.sh   fills raw URLs and validation step IDs
```

## 7. Tested before hand-off (offline)

- Mock API run locally: every endpoint, all error codes, and structured request logs.
- Holly solution run through the **real ADK 2.13 Runner** against the local API, with a scripted model in place of Gemini. The checks covered tool calls, the right account, two tools in one turn, a handled `ACCOUNT_NOT_FOUND`, the bonus tool, and the trace output. A crashing tool was also tested and produces `TOOL_CRASH`.
- All six validators run in PowerShell 7 against a simulated `gcloud`, with pass and fail scenarios for each. Prepare's build path was tested too: source download, build submit with the builder identity, polling, and the retry message.
- **Not yet tested in a real CloudLabs GCP project.** That needs the presales tenant: the first Cloud Build run, org-policy effects on the public Cloud Run endpoint, and real Gemini behaviour.
