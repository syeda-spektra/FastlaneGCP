# ❓ Task 4: Account Not Found

<p align="center"><b>🧦 Day 2: Stocking Fillers</b> | 🛷 Track A: Developer | 🏆 Challenge</p>

*A customer types* **HB-99999** *instead of* **HB-10234**.

🎯 **Goal:** When an account can't be found, Holly's balance tool reports it cleanly and Holly replies kindly, without ever making up an amount.

📜 **Rules**

- For an unknown account, `get_account_balance` returns `"status": "error"` with `"error_code": "ACCOUNT_NOT_FOUND"`. It must **not** raise an exception.
- Holly apologises, asks the customer to check the number, and gives **no money amount** in that reply.
- Ask Holly for the balance of an account that doesn't exist, wait about **1 minute**, then validate.

💡 **Hints**

- You found the API's error code for a missing account in Task 1.
- If a tool raises, the trace records a `TOOL_CRASH`. Search Cloud Logging for `logName:holly-trace` to see what the validators see.
- An invalid format such as `12345` deserves the same kind treatment.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="415b13f9-a9fe-4cdb-b4b0-581bd8dc724f" />

---

### 👉 Select **Next >>** to continue to the Christmas Bonus.
