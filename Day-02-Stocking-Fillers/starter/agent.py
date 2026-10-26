# =============================================================================
# 🎁 Day 2: Stocking Fillers - Holly starter file
# 12 Days of AI Agents | Track A: Developer | Hollyfield Building Society
#
# Holly can chat, but she can't see a single real balance yet. Give her two
# function tools that call Hollyfield's core-banking API on Cloud Run.
#
# Complete the TODOs. Do NOT change the "Elf trace" section or the callbacks
# on root_agent: the validators read Holly's trace in Cloud Logging.
# =============================================================================
import json
import os
import subprocess
from typing import Any, Optional

import requests
from google.adk.agents import Agent

CORE_BANKING_URL = os.environ.get("CORE_BANKING_URL", "").rstrip("/")


# -----------------------------------------------------------------------------
# 🧝 Elf trace - DO NOT CHANGE. Writes Holly's tool calls and answers to the
# Cloud Logging log "holly-trace" so you (and the validators) can see them.
# -----------------------------------------------------------------------------
_cloud_logger = None
_cloud_logging_ok = True


def _trace(message: str, **fields: Any) -> None:
    global _cloud_logger, _cloud_logging_ok
    entry = {"message": message, "app": "holly", "lab": "day02", **fields}
    print("[holly-trace] " + json.dumps(entry, default=str)[:600], flush=True)
    if not _cloud_logging_ok:
        return
    try:
        if _cloud_logger is None:
            from google.cloud import logging as cloud_logging
            _cloud_logger = cloud_logging.Client(
                project=os.environ.get("GOOGLE_CLOUD_PROJECT")).logger("holly-trace")
        _cloud_logger.log_struct(json.loads(json.dumps(entry, default=str)), severity="INFO")
    except Exception as exc:  # keep Holly running even if logging is unavailable
        _cloud_logging_ok = False
        print(f"[holly-trace] WARNING: Cloud Logging unavailable ({exc}). Trace is local only.", flush=True)


def _session_id(ctx: Any) -> str:
    try:
        return ctx.session.id
    except Exception:
        return ""


def trace_tool_call(tool: Any, args: dict, tool_context: Any, tool_response: Any) -> Optional[dict]:
    """after_tool_callback: records every tool call and its outcome."""
    response = tool_response if isinstance(tool_response, dict) else {"result": tool_response}
    _trace("TOOL_CALL",
           tool=getattr(tool, "name", str(tool)),
           args=args,
           status=str(response.get("status", "missing")),
           error_code=str(response.get("error_code", "")),
           result=json.dumps(response, default=str)[:1500],
           invocation_id=tool_context.invocation_id,
           session_id=_session_id(tool_context))
    return None


def trace_tool_crash(tool: Any, args: dict, tool_context: Any, error: Exception) -> Optional[dict]:
    """on_tool_error_callback: records a tool that raised instead of returning an error."""
    _trace("TOOL_CRASH",
           tool=getattr(tool, "name", str(tool)),
           args=args,
           error=f"{type(error).__name__}: {error}",
           invocation_id=tool_context.invocation_id,
           session_id=_session_id(tool_context))
    return {"status": "error", "error_code": "TOOL_CRASHED",
            "message": "The tool raised an exception instead of returning an error."}


def trace_answer(callback_context: Any, llm_response: Any) -> None:
    """after_model_callback: records Holly's final text answers."""
    content = getattr(llm_response, "content", None)
    if not content or not content.parts or getattr(llm_response, "partial", False):
        return None
    if any(getattr(p, "function_call", None) for p in content.parts):
        return None
    text = "".join(p.text for p in content.parts if getattr(p, "text", None))
    if text.strip():
        _trace("AGENT_ANSWER", text=text[:2000],
               invocation_id=callback_context.invocation_id,
               session_id=_session_id(callback_context))
    return None


# -----------------------------------------------------------------------------
# 🛠️ Elves' helper - calls the core-banking API. You may use it as it is.
# -----------------------------------------------------------------------------
_id_token: Optional[str] = None


def call_core_banking(path: str) -> tuple[int, dict]:
    """GET <CORE_BANKING_URL><path>. Returns (http_status, json_body). Never raises.

    The API returns errors as: {"error": {"code": "...", "message": "..."}}
    If the API cannot be reached, returns (503, {"error": {"code": "API_UNAVAILABLE", ...}}).
    """
    global _id_token
    if not CORE_BANKING_URL:
        return 503, {"error": {"code": "API_UNAVAILABLE",
                               "message": "CORE_BANKING_URL is not set in holly/.env."}}
    headers = {"X-Hollyfield-Client": "holly-adk"}
    for attempt in range(2):
        if _id_token:
            headers["Authorization"] = f"Bearer {_id_token}"
        try:
            resp = requests.get(CORE_BANKING_URL + path, headers=headers, timeout=10)
        except requests.RequestException as exc:
            return 503, {"error": {"code": "API_UNAVAILABLE",
                                   "message": f"The core-banking API could not be reached: {exc}"}}
        if resp.status_code in (401, 403) and attempt == 0 and not _id_token:
            try:  # the API may require an identity token in some tenants
                _id_token = subprocess.run(["gcloud", "auth", "print-identity-token"],
                                           capture_output=True, text=True, timeout=20).stdout.strip() or None
            except Exception:
                _id_token = None
            if _id_token:
                continue
        try:
            body = resp.json()
        except ValueError:
            body = {"error": {"code": "BAD_RESPONSE", "message": resp.text[:200]}}
        return resp.status_code, body
    return 503, {"error": {"code": "API_UNAVAILABLE", "message": "The core-banking API refused the request."}}


# -----------------------------------------------------------------------------
# 🧦 Holly's tools - YOUR WORK STARTS HERE
# -----------------------------------------------------------------------------
# TODO 1: Write get_account_balance(account_id: str) -> dict
#   - Calls GET /v1/accounts/<account_id>/balance through call_core_banking().
#   - Needs a docstring that tells Gemini WHEN to use it and what account_id looks like.
#   - Follows Holly's tool contract (see the lab guide): it returns a dict with
#     "status": "success" or "error" and NEVER raises.

# TODO 2: Write get_savings_rates() -> dict
#   - Calls GET /v1/savings/rates and follows the same tool contract.


root_agent = Agent(
    name="holly",
    model=os.environ.get("AGENT_MODEL", "gemini-2.5-flash"),
    description="Holly, Hollyfield Building Society's customer agent.",
    # TODO 3: Extend Holly's instruction so she uses her tools for balances and rates,
    #         never guesses a number, and handles an account that can't be found kindly.
    instruction=(
        "You are Holly, the friendly customer agent of Hollyfield Building Society, a UK building society. "
        "You help customers with their savings accounts and Hollyfield's festive savings products. "
        "Be warm and concise. Politely decline anything that is not about Hollyfield banking."
    ),
    # TODO 4: Give Holly her tools.
    tools=[],
    # 🧝 Elf trace - DO NOT REMOVE these three lines.
    after_tool_callback=trace_tool_call,
    on_tool_error_callback=trace_tool_crash,
    after_model_callback=trace_answer,
)
