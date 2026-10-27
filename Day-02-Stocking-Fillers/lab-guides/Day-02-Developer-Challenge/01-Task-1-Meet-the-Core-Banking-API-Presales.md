# 🔎 Task 1: Meet the Core-Banking API

<p align="center"><b>🧦 Day 2: Stocking Fillers</b> | 🛷 Track A: Developer | 🏆 Challenge</p>

## ⚙️ Before You Begin: Lab Readiness Check

Hollyfield's core-banking API is built and deployed into your project the first time you run this check. It also turns on the Google Cloud services your lab needs.

1. Select the **Validate** button below.

1. Wait for the **Success** message before you continue. The first run takes **3–4 minutes**: if you see *"still building"*, wait 2 minutes and select **Validate** again.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="e42b0e80-cf46-4e99-8162-0aaf3e1b443d" />

## 🔐 Enter the Ops Room

1. On the lab VM desktop, open the **Google Cloud Console** shortcut and sign in:

   - Email/Username: <inject key="AzureADUserEmail" enableCopy="true"/>
   - Password: <inject key="AzureADUserPassword" enableCopy="true"/>

1. Select your project <inject key="ProjectId" enableCopy="false"/> and open **Cloud Shell** (**>_**).

1. Load your Hollyfield toolkit. These variables are used in every task:

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

## 🎯 Your Task

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

   <validation step="d449f70c-6ea4-4340-b775-5c19a2b70041" />

---

### 👉 Select **Next >>** to continue to Task 2: Write Holly's Tools.
