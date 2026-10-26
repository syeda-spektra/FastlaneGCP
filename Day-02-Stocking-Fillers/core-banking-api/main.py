# =============================================================================
# Hollyfield Building Society - mock core-banking API (synthetic data only)
# 12 Days of AI Agents | Track A: Developer | Day 2: Stocking Fillers
#
# Runs on Cloud Run as "hollyfield-core-banking". Holly's function tools call it.
#
#   GET /healthz                              -> service health
#   GET /v1/accounts/<account_id>/balance     -> balance of one savings account
#   GET /v1/savings/rates[?product=<code>]    -> current savings rates (AER)
#
# Every request is written to stdout as one JSON line (message API_REQUEST).
# Cloud Run sends it to Cloud Logging as jsonPayload, where the lab
# validators read it.
# =============================================================================
import json
import os
import re
from datetime import datetime, timezone

from flask import Flask, jsonify, request

app = Flask(__name__)

_DATA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "core-banking-data.json")
with open(_DATA_FILE, encoding="utf-8") as fh:
    DATA = json.load(fh)

ACCOUNTS = {a["account_id"]: a for a in DATA["accounts"]}
PRODUCTS = {p["product_code"]: p for p in DATA["products"]}
ACCOUNT_ID_PATTERN = re.compile(r"^HB-\d{5}$")


def _log(severity: str, message: str, **fields) -> None:
    print(json.dumps({"severity": severity, "message": message, **fields}), flush=True)


def _error(status: int, code: str, message: str):
    return jsonify({"error": {"code": code, "message": message},
                    "data_version": DATA["version"]}), status


@app.after_request
def _log_request(response):
    if request.path != "/healthz":
        _log("INFO" if response.status_code < 500 else "ERROR", "API_REQUEST",
             method=request.method,
             path=request.path,
             query=request.query_string.decode("utf-8", "ignore"),
             status=response.status_code,
             account_id=(request.view_args or {}).get("account_id", ""),
             client=request.headers.get("X-Hollyfield-Client", "unknown"),
             data_version=DATA["version"])
    return response


@app.get("/healthz")
def healthz():
    return jsonify({"status": "ok", "service": "hollyfield-core-banking", "data_version": DATA["version"]})


@app.get("/v1/accounts/<account_id>/balance")
def get_balance(account_id: str):
    normalised = account_id.strip().upper()
    if not ACCOUNT_ID_PATTERN.match(normalised):
        return _error(400, "INVALID_ACCOUNT_ID",
                      f"'{account_id}' is not a Hollyfield account number. Account numbers look like HB-12345.")
    account = ACCOUNTS.get(normalised)
    if account is None:
        return _error(404, "ACCOUNT_NOT_FOUND", f"No Hollyfield account matches {normalised}.")
    product = PRODUCTS[account["product_code"]]
    return jsonify({
        "account_id": account["account_id"],
        "account_holder": account["account_holder"],
        "product_code": account["product_code"],
        "product_name": product["product_name"],
        "currency": "GBP",
        "balance": account["balance"],
        "available_balance": account["available_balance"],
        "as_of": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "data_version": DATA["version"],
    })


@app.get("/v1/savings/rates")
def get_rates():
    product = request.args.get("product", "").strip().upper()
    products = DATA["products"]
    if product:
        if product not in PRODUCTS:
            return _error(404, "PRODUCT_NOT_FOUND",
                          f"No savings product with code {product}. Codes: {', '.join(sorted(PRODUCTS))}.")
        products = [PRODUCTS[product]]
    return jsonify({
        "currency": "GBP",
        "effective_from": DATA["rates_effective_from"],
        "data_version": DATA["version"],
        "products": products,
    })


@app.errorhandler(404)
def not_found(_):
    return _error(404, "NOT_FOUND", "Unknown endpoint. Try /v1/accounts/<account_id>/balance or /v1/savings/rates.")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
