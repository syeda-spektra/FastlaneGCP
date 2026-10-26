<h1 align="center">🧦 Day 2: Stocking Fillers 🎁</h1>
<p align="center"><b>❄️ 12 Days of AI Agents: The Christmas Change Freeze ❄️</b> | <b>🛷 Track A: Developer</b> | 🏆 <b>Challenge</b> | ⏱️ <b>Estimated Timing: 60 Minutes</b> | 🎖️ <b>Badge: Toolsmith</b></p>
<p align="center">🔔 ✨ 🦌 🎄 🦌 ✨ 🔔</p>

---

## 🎄 The Mission

It's the busiest fortnight of the year at **Hollyfield Building Society** 🏦. Festive spending is up, savings-club payouts are due, and the Christmas change freeze starts on **Christmas Eve**. Yesterday you woke up **Holly**, Hollyfield's new customer agent. Today customers want their **real** balance, not a general answer.

Hollyfield's contact centre is flooded with festive questions:

- 💷 *"How much is in my Christmas Saver?"*
- 📈 *"What rate does the Christmas Saver pay?"*
- 🎁 *"What's my balance, and what rate am I getting?"*

Holly can chat, but she can't see a single real number. Hollyfield's **core-banking API** already runs on **Cloud Run**. Your job is to give Holly **function tools** that call it, describe them so Gemini calls them correctly, and make sure a wrong account number never turns into a guessed balance.

Hollyfield's one unbreakable rule: **Holly never invents a number.** Every balance and every rate must come from the core-banking API.

**🧭 How this lab works**

- 🎯 This is the **Challenge** version: each task gives you a **goal**, the **rules** your solution must follow and a few **hints**. There are no copy-and-paste steps. (The **Guided** version of Day 2 has step-by-step instructions, but earns fewer points.)
- ✅ The validators check your **result**, not the commands you used. Validate as often as you like; there is no penalty and no limit.
- 🎄 The **Christmas Bonus** at the end is optional: try it if you have time left.
- 🧠 A short Knowledge Check closes the lab.

---

## 🗺️ Today's Route

| Stop | Task |
|:---:|---|
| 🔎 | **Task 1: Meet the Core-Banking API** – get your lab ready, then explore the API Holly will call |
| 🛠️ | **Task 2: Write Holly's Tools** – a balance tool and a savings-rates tool |
| 🧦 | **Task 3: Register and Test** – give Holly her tools and ask questions that need both |
| ❓ | **Task 4: Account Not Found** – handle the wrong account number kindly |
| 🎄 | **Christmas Bonus** – interest by New Year (optional) |
| 🧠 | **Knowledge Check** – 3 questions |

---

## 🗺️ The Road to the Change Freeze

| Day | Lab | Status |
|:---:|---|:---:|
| 1 | 🔔 **Holly Wakes Up** | ✅ Done |
| 2 | 🧦 **Stocking Fillers** | 📍 **Today** |
| 3 | 🌙 **Silent Night, Grounded Answers** | 🔜 |
| 4 | 🧠 **Holly Remembers** | 🔜 |
| 5 | 🎁 **Ask Before You Wrap** | 🔜 |
| 6 | 🌿 **The Holly and the Ivy** | 🔜 |
| 7 | 🥧 **The Mince Pie Mob** | 🔜 |
| 8 | 😇 **Naughty or Nice?** | 🔜 |
| 9 | ☁️ **Deck the Cloud** | 🔜 |
| 10 | 🚪 **Who Goes There?** | 🔜 |
| 11 | ✨ **All Is Calm, All Is Bright** | 🔜 |
| 12 | 🎅 **Christmas Eve Go-Live** | 🏁 Capstone |

---

## 🏗️ Today's Architecture

```
 You (Cloud Shell)
   │  adk web / adk run
   ▼
 ┌──────────────────────────────┐  get_account_balance()   ┌─────────────────────────────────────┐
 │ Holly (ADK agent, Python)    │  get_savings_rates()     │ Cloud Run: hollyfield-core-banking  │
 │ Gemini 2.5 Flash, Vertex AI  │ ───────────────────────▶ │  /v1/accounts/<id>/balance          │
 │ (us-central1)                │      HTTPS + JSON        │  /v1/savings/rates                  │
 └──────────────┬───────────────┘                          └─────────────────────────────────────┘
                │ Elf trace (callbacks)
                ▼
     Cloud Logging: holly-trace   (tool calls, results, answers)
```

---

## 🖥️ Lab Environment

The lab window is split into two parts:

- **Left side:** your lab virtual machine (VM), a Windows workstation with a browser.
- **Right side:** the lab guide, with the tasks to complete.

![Lab layout](../media/gs-lab-layout1.png)

Your environment is an **isolated Google Cloud project** created only for you. All data in it is **synthetic**: no real customers, accounts or rates. It has been pre-provisioned with:

| Resource | Value |
|---|---|
| ☁️ **Project ID** | <inject key="ProjectId" enableCopy="true"/> |
| 🌍 **Region** | <inject key="Region" enableCopy="true"/> |
| 🧰 **Hollyfield workbench bucket** | <inject key="WorkbenchBucket" enableCopy="true"/> |
| 🏦 **Core-banking API (Cloud Run service)** | <inject key="CoreBankingService" enableCopy="true"/> |
| 👩 **Test customer** | **Eleanor Frost**, Christmas Saver account **HB-10234** |

---

## 📜 Holly's Tool Contract

Every tool you write today must follow this contract. The validators depend on it.

| Outcome | The tool returns |
|---|---|
| ✅ Success | a dict with `"status": "success"` and the data Holly needs |
| ❌ Any failure | a dict with `"status": "error"`, an `"error_code"` (use the API's code, for example `ACCOUNT_NOT_FOUND`) and a short `"message"` |
| 💥 Never | raising an exception |

---

## 🧭 Lab Window Controls

![Lab window controls](../media/gs-topbar.png)

| # | Control | Use |
|:---:|---|---|
| 1 | **VM name** | Shows the lab VM you are connected to. |
| 2 | **Timer** | Time remaining in your lab session. |
| 3 | **Progress bar** | Your progress through the lab. |
| 4 | **A↕** | Change the text size of the lab guide. |
| 5 | **Refresh** | Reconnect the VM if the screen stops responding. |
| 6 | **More (...)** | Language, Delete and VM Native Clipboard options. |
| 7 | **Lab guide menu** | Guide, Environment, Progress, Resources and Help. |
| 8 | **Split window** | Split the lab guide and the VM into separate windows. |

### 6️⃣ More Options

![More options](../media/gs-more-menu.png)

| Option | Use |
|---|---|
| 🌍 **Language** | Switch the lab language, if multi-language support is enabled. |
| 🗑️ **Delete** | Delete the environment once your lab is complete. |
| 📋 **VM Native Clipboard** | Allows copying files within the VM. While it is on, text copied from your local PC cannot be pasted into the VM using keyboard shortcuts. You can turn it off at any time from **More (...)**. |

### 7️⃣ Lab Guide Menu

![Menu](../media/gs-tabs.png)

| Option | Use |
|---|---|
| 📖 **Guide** | All tasks and lab information. |
| 🔑 **Environment** | All required credentials and lab details. |
| 📈 **Progress** | Your points for validations and questions. |
| ⚙️ **Resources** | Start and stop the lab VM. |
| ❓ **Help** | Support information. |

### 📈 Progress

The **Progress** tab shows your overall points, with separate views for **Validations** and **Questions**.

![Progress tab](../media/gs-progress1.png)

### 📄 Page Navigation

Use **Previous**, the page numbers and **Next** at the bottom of the guide to move between pages.

![Page navigation](../media/gs-pagination1.png)

---

## ✅ Validate Your Work

1. Complete the task.
1. Scroll to the **Validation Check** under it.
1. Click **Validate**.

![Validate button](../media/gs-validate.png)

- 🎉 On success, the status shows **Success** and the points are added to your **Progress**.
- 🔧 If a check fails, read the message, fix the issue and click **Validate** again.

> 💡 **Tip:** Task 1 starts with a **lab readiness check**. Click its **Validate** button before anything else and wait for **Success**: it builds Hollyfield's core-banking API, which takes **3–4 minutes** the first time.

---

## 🔐 Sign In to Google Cloud

1. On the lab VM desktop, double-click the **Google Cloud Console** shortcut.
1. Sign in with the following credentials:

    | Detail | Value |
    |---|---|
    | 👤 **Username** | <inject key="AzureADUserEmail" enableCopy="true"/> |
    | 🔒 **Password** | <inject key="AzureADUserPassword" enableCopy="true"/> |

1. If prompted, accept the **Terms of Service**.
1. From the project selector, select your project <inject key="ProjectId" enableCopy="false"/>.

> ⚠️ **Note:** Use only the credentials above. Do not sign in with a personal Google account.

---

## 🔌 Connect Using RDP (Optional)

To use your own RDP client instead of the browser-based VM, connect with these details:

| Detail | Value |
|---|---|
| **Computer** | <inject key="vmPublicIp" enableCopy="true"/> |
| **Username** | <inject key="vmUsername" enableCopy="true"/> |
| **Password** | <inject key="vmPassword" enableCopy="true"/> |

---

## 🆘 Support Contact

The CloudLabs support team is available 24/7 via email and live chat.

- 📧 **Email:** <a href="mailto:cloudlabs-support@spektrasystems.com">cloudlabs-support@spektrasystems.com</a>
- 💬 **Live chat:** <a href="https://support.cloudlabs.ai/isv">https://support.cloudlabs.ai/isv</a>

---

Click **Next** to start **Task 1: Meet the Core-Banking API**. 🔎

## 🎄 Happy Learning, and Merry Christmas! 🎅
