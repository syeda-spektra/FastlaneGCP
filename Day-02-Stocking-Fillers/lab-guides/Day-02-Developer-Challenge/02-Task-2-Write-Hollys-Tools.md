# 🛠️ Task 2: Write Holly's Tools

<p align="center"><b>🧦 Day 2: Stocking Fillers</b> | 🛷 Track A: Developer | 🏆 Challenge</p>

🎯 **Goal:** Write Holly's two function tools: one that gets a customer's **balance** and one that gets the current **savings rates**, both from the live core-banking API.

📜 **Rules**

- Holly lives in a folder named **`~/holly`** containing `__init__.py`, `agent.py` and `requirements.txt`. Start from the starter files and complete **TODO 1** and **TODO 2** in `agent.py`:

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

- Write exactly these two tools:

   | Tool | Calls |
   |---|---|
   | `get_account_balance(account_id: str) -> dict` | `GET /v1/accounts/<account_id>/balance` |
   | `get_savings_rates() -> dict` | `GET /v1/savings/rates` |

- Both tools follow **Holly's Tool Contract** (on the Getting Started page).
- Each tool has a **docstring** that tells Gemini **when** to use it. The docstring of `get_account_balance` also describes `account_id` and its `HB-12345` format.
- No hard-coded balances or rates: every number comes from the API.
- Do **not** change the **Elf trace** section or the three callback lines on `root_agent`.
- When your tools work, upload `agent.py`, `__init__.py` and `requirements.txt` to **`gs://$BENCH/app/holly`** so they can be validated. Do **not** upload `.env`.

💡 **Hints**

- `call_core_banking(path)` in the starter already calls the API and returns `(http_status, json_body)`. It never raises.
- ADK builds each tool's description from its **name**, **type hints** and **docstring**. A vague docstring makes Holly forget her tools.
- You can try a tool on its own before Holly uses it:

   ```bash
   cd ~ && CORE_BANKING_URL=$API_URL python3 -c "from holly.agent import get_account_balance; print(get_account_balance('HB-10234'))"
   ```

- `gcloud storage cp` can copy several files in one command.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="{{STEP_T2}}" />

---

### 👉 Select **Next >>** to continue to Task 3: Register and Test.
