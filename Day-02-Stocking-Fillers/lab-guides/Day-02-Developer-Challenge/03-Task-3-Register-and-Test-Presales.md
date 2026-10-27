# 🧦 Task 3: Register and Test

<p align="center"><b>🧦 Day 2: Stocking Fillers</b> | 🛷 Track A: Developer | 🏆 Challenge</p>

🎯 **Goal:** Give Holly her two tools and prove she answers balance and rate questions from the live API, including **one** question that needs **both** tools.

📜 **Rules**

- Register both tools with Holly (**TODO 4**) and extend her instruction (**TODO 3**) so she uses the right tool for each question and **never guesses a number**.
- Test Holly with:
   1. the balance of Eleanor Frost's Christmas Saver, **HB-10234**;
   1. the rate the **Christmas Saver** pays;
   1. **one** question that needs both, for example *"For HB-10234, what's my balance and what rate am I getting?"*
- Wait about **1 minute**, then validate.

💡 **Hints**

- Run Holly with `adk web` from your home folder (then **Web Preview** on port 8000) or with `adk run holly`. In `adk web`, the **Events** tab shows every tool call and its result.
- Holly's instruction is her guardrail: tell her which tool answers which question.
- The validators read Holly's trace in Cloud Logging. Search **Logs Explorer** for `logName:holly-trace` to see what they see.

   > **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
   >
   > - Select the **Validate** button for the corresponding task. If you receive a success message, you can proceed to the next task.
   > - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
   > - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

   <validation step="d38fb1fc-68d4-4e34-8abf-c78aee2fd936" />

---

### 👉 Select **Next >>** to continue to Task 4: Account Not Found.
