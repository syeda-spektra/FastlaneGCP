# 🧦 Day 2: Stocking Fillers 🎁

### ⏱️ Estimated Duration: 60 Minutes

### 🛷 Track A: Developer &nbsp;|&nbsp; Version: Challenge &nbsp;|&nbsp; Points: 100 (+10 Christmas Bonus) &nbsp;|&nbsp; 🎖️ Badge: **Toolsmith**

<p align="center">🔔 ✨ 🦌 🎄 🦌 ✨ 🔔</p>

## 🎄 The Mission

*Customers want their real balance, not a general answer.*

Hollyfield's contact centre is flooded with festive questions:

- 💷 *"How much is in my Christmas Saver?"*
- 📈 *"What rate does the Christmas Saver pay?"*
- 🎁 *"What's my balance, and what rate am I getting?"*

Holly can chat, but she can't see a single real number. Hollyfield's **core-banking API** already runs on **Cloud Run**. Your job is to give Holly **function tools** that call it, describe them so Gemini calls them correctly, and make sure a wrong account number never turns into a guessed balance.

Hollyfield's one unbreakable rule: **Holly never invents a number.** Every balance and every rate must come from the core-banking API.

> 🧭 **This is a challenge lab.** Each challenge gives you a **goal**, the **rules** your solution must follow and a few **hints**. How you get there is up to you. The validators check the **result**, not the commands you used.

## 🗺️ Today's Route

| Stop | Challenge | Points |
|:---:|---|:---:|
| 🏦 | **Challenge 1: Hollyfield Ops Room** – prepare your environment | 5 |
| 🔎 | **Challenge 2: Meet the Core-Banking API** – learn the API before Holly does | 10 |
| 🧦 | **Challenge 3: Stocking Fillers** – give Holly her tools | 35 |
| ❓ | **Challenge 4: Account Not Found** – handle the wrong account number | 25 |
| 🎁 | **Challenge 5: Wrap the Gift** – pass the elves' code review | 19 |
| 🎄 | **Christmas Bonus** – interest by New Year (optional) | +10 |
| 🧠 | **Knowledge Check** – 3 questions | 6 |

## 🏗️ Today's Architecture

```
 You (Cloud Shell)
   │  adk web / adk run
   ▼
 ┌──────────────────────────────┐  get_account_balance()   ┌──────────────────────────────────┐
 │ Holly (ADK agent, Python)    │  get_savings_rates()     │ Cloud Run: hollyfield-core-banking│
 │ Gemini 2.5 Flash, Vertex AI  │ ───────────────────────▶ │  /v1/accounts/<id>/balance        │
 │ (us-central1)                │      HTTPS + JSON        │  /v1/savings/rates                │
 └──────────────┬───────────────┘                          └──────────────────────────────────┘
                │ Elf trace (callbacks)
                ▼
     Cloud Logging: holly-trace   (tool calls, results, answers)
```

## 🏦 Your Hollyfield

| Resource | Value |
|---|---|
| ☁️ Project ID | <inject key="ProjectId" enableCopy="true"/> |
| 🌍 Region | <inject key="Region" enableCopy="true"/> |
| 🧰 Workbench bucket | <inject key="WorkbenchBucket" enableCopy="true"/> |
| 🏦 Core-banking API service | <inject key="CoreBankingService" enableCopy="true"/> |
| 👩 Test customer | **Eleanor Frost**, Christmas Saver account **HB-10234** |

## 📜 Holly's Tool Contract

Every tool you write today must follow this contract. The validators depend on it.

| Outcome | The tool returns |
|---|---|
| ✅ Success | a dict with `"status": "success"` and the data Holly needs |
| ❌ Any failure | a dict with `"status": "error"`, an `"error_code"` (use the API's code, for example `ACCOUNT_NOT_FOUND`) and a short `"message"` |
| 💥 Never | raising an exception |

---

## 🏦 Challenge 1: Hollyfield Ops Room

### ⚙️ Task 1: Prepare Hollyfield

1. This one-time setup turns on the Google Cloud services and **builds and deploys Hollyfield's core-banking API** to Cloud Run.

1. Select the **Validate** button below. The first build takes **3–4 minutes**: if you see *"still building"*, wait 2 minutes and select **Validate** again until you see **Success**.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_EX1}}" />

### 🔐 Task 2: Enter the Ops Room

1. On the lab VM desktop, open the **Google Cloud Console** shortcut and sign in:

   - Email/Username: <inject key="AzureADUserEmail" enableCopy="true"/>
   - Password: <inject key="AzureADUserPassword" enableCopy="true"/>

1. Select your project <inject key="ProjectId" enableCopy="false"/> and open **Cloud Shell** (**>_**).

1. Load your Hollyfield toolkit. These variables are used in every challenge:

   ```bash
   export PROJECT_ID=<inject key="ProjectId" enableCopy="false"/>
   export REGION=<inject key="Region" enableCopy="false"/>
   export BENCH=<inject key="WorkbenchBucket" enableCopy="false"/>
   gcloud config set project $PROJECT_ID
   export API_URL=$(gcloud run services describe <inject key="CoreBankingService" enableCopy="false"/> --region $REGION --format 'value(status.url)')
   echo "Core-banking API: $API_URL"
   ```

1. Set up a Python environment for Holly:

   ```bash
   python3 -m venv ~/holly-venv && source ~/holly-venv/bin/activate
   pip install --quiet --upgrade google-adk google-cloud-logging requests
   ```

   > 📝 **Note:** If Cloud Shell restarts, load the toolkit again and run `source ~/holly-venv/bin/activate`.

---

## 🔎 Challenge 2: Meet the Core-Banking API

🎯 **Goal:** Learn exactly what the core-banking API returns, including when things go wrong, before Holly ever calls it.

📜 **Rules**

- Call the API from Cloud Shell. It has two endpoints:

   | Endpoint | Returns |
   |---|---|
   | `GET /v1/accounts/<account_id>/balance` | the live balance of one savings account |
   | `GET /v1/savings/rates` | the current rate (AER) of every savings product |

- Read the savings rates, read the balance of Eleanor Frost's account **HB-10234**, and ask for the balance of an account that **does not exist**.
- Wait about **1 minute** for the API's logs to reach Cloud Logging, then validate.

🔎 **Find the answers yourself**

- What is the balance of **HB-10234**, and which product is it?
- What AER does the **Christmas Saver** pay? Is it fixed or variable?
- What **HTTP status** and **error code** does the API return for an account that doesn't exist? And for `12345`?

💡 **Hints**

- `curl -s "$API_URL/..." | jq` makes the JSON easy to read.
- Errors always come back as `{"error": {"code": "...", "message": "..."}}`. Holly's tools will need to pass that code on.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_EX2}}" />

---

## 🧦 Challenge 3: Stocking Fillers

🎯 **Goal:** Give Holly two function tools so she answers balance and rate questions from the live core-banking API, including a question that needs **both**.

📜 **Rules**

- Holly lives in a folder named **`~/holly`** containing `__init__.py`, `agent.py` and `requirements.txt`. Start from the starter files and complete the **TODOs**:

   | File | Starter |
   |---|---|
   | `agent.py` | `https://raw.githubusercontent.com/syeda-spektra/FastlaneGCP/refs/heads/main/Day-02-Stocking-Fillers/starter/agent.py` |
   | `__init__.py` | `https://raw.githubusercontent.com/syeda-spektra/FastlaneGCP/refs/heads/main/Day-02-Stocking-Fillers/starter/__init__.py` |
   | `requirements.txt` | `https://raw.githubusercontent.com/syeda-spektra/FastlaneGCP/refs/heads/main/Day-02-Stocking-Fillers/starter/requirements.txt` |

- Holly's settings go in `~/holly/.env`:

   | Setting | Value |
   |---|---|
   | `GOOGLE_GENAI_USE_VERTEXAI` | `TRUE` |
   | `GOOGLE_CLOUD_PROJECT` | your project |
   | `GOOGLE_CLOUD_LOCATION` | your region |
   | `CORE_BANKING_URL` | the core-banking API URL (`$API_URL`) |

- Write exactly these two tools, and register both with Holly:

   | Tool | Calls |
   |---|---|
   | `get_account_balance(account_id: str) -> dict` | `GET /v1/accounts/<account_id>/balance` |
   | `get_savings_rates() -> dict` | `GET /v1/savings/rates` |

- Both tools follow **Holly's Tool Contract** (above).
- Do **not** change the **Elf trace** section or the three callback lines on `root_agent`. They write every tool call and answer to Cloud Logging (log `holly-trace`), which is what the validators read.
- Test Holly with:
   1. the balance of Eleanor Frost's Christmas Saver, **HB-10234**;
   1. the rate the **Christmas Saver** pays;
   1. **one** question that needs both, for example *"For HB-10234, what's my balance and what rate am I getting?"*
- Wait about **1 minute**, then validate.

💡 **Hints**

- `call_core_banking(path)` in the starter already calls the API and returns `(http_status, json_body)`. It never raises.
- ADK builds each tool's description from its **name**, **type hints** and **docstring**. A vague docstring makes Holly forget her tools. Say *when* to use the tool and what `account_id` looks like.
- Run Holly with `adk web` from your home folder (then **Web Preview** on port 8000) or with `adk run holly`. In `adk web`, the **Events** tab shows every tool call and its result.
- Holly's instruction is her guardrail: tell her which tool answers which question, and that she must never guess a number.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_EX3}}" />

---

## ❓ Challenge 4: Account Not Found

*A customer types* **HB-99999** *instead of* **HB-10234**.

🎯 **Goal:** When an account can't be found, Holly's tool reports it cleanly and Holly replies kindly, without ever making up an amount.

📜 **Rules**

- For an unknown account, `get_account_balance` returns `"status": "error"` with `"error_code": "ACCOUNT_NOT_FOUND"`. It must **not** raise an exception.
- Holly apologises, asks the customer to check the number, and gives **no money amount** in that reply.
- Ask Holly for the balance of an account that doesn't exist, wait about **1 minute**, then validate.

💡 **Hints**

- You found the API's error code for a missing account in Challenge 2.
- If a tool raises, the trace records a `TOOL_CRASH`. Search Cloud Logging for `logName:holly-trace` to see what the validators see.
- An invalid format such as `12345` deserves the same kind treatment.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_EX4}}" />

---

## 🎁 Challenge 5: Wrap the Gift

🎯 **Goal:** Hand Holly's tools to Hollyfield's elves for code review before tomorrow's work starts.

📜 **Rules**

- Upload your `~/holly` folder (`agent.py`, `__init__.py`, `requirements.txt`) to **`gs://$BENCH/app/holly`**. Do **not** upload `.env`.
- The elves' code review checks that:
   - both tools are defined and registered with Holly;
   - each tool has a docstring that says when to use it, and `get_account_balance` describes `account_id` and its `HB-12345` format;
   - the tools return an `error_code` on failure (Holly's Tool Contract);
   - the Elf trace callbacks are unchanged;
   - no balance is hard-coded.

💡 **Hints**

- `gcloud storage cp` can copy several files in one command.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_EX5}}" />

---

## 🎄 Christmas Bonus: Interest by New Year (optional, +10)

🎯 **Goal:** Eleanor asks: *"How much interest will HB-10234 earn by New Year?"* Give Holly a third tool that works it out.

📜 **Rules**

- The tool's name must contain **`interest`**, it takes an `account_id`, and it follows Holly's Tool Contract.
- It uses the account's **live** balance and its product's **live** AER. No hard-coded numbers.
- Ask Holly the question, wait about **1 minute**, then validate.

💡 **Hints**

- A tool can call other tools: it is just Python.
- Holly should say it is an **estimate** (balance and rate unchanged, before tax).

   <validation step="{{STEP_EX6}}" />

---

## 🎖️ Badge Unlocked: Toolsmith

<p align="center">🎄 🎖️ <b>TOOLSMITH</b> 🎖️ 🎄</p>

Holly's stocking is full! Today you:

- ✅ Explored a live **core-banking API** on **Cloud Run**, including its errors.
- ✅ Wrote **ADK function tools** and described them so Gemini calls the right one.
- ✅ Made Holly combine **two tools** in one answer.
- ✅ Handled an unknown account with a **structured error** instead of a crash or a guess.

🔜 **Next stop on the road to the change freeze:** 🌙 **Silent Night, Grounded Answers.** Holly guessed a fee and got it wrong. Time to ground her in the small print.

### 👉 Select **Next >>** to continue to the Knowledge Check. 🧝
