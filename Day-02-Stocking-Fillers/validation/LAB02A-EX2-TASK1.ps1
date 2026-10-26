<#
 CloudLabs validation | LAB02A-EX2-TASK1
 Task 2: Holly's Tools Are Written   (25 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShell        Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - gs://<workbench>/app/holly has agent.py + requirements.txt; get_account_balance and
     get_savings_rates defined with docstrings (balance one describes account_id / HB-12345);
     error_code contract used; trace callbacks intact; no hard-coded balances
#>
param(
    [string]$DeploymentId,
    [string]$projectname
)

$region      = "us-central1"
$serviceName = "hollyfield-core-banking"
$homeAccount = "HB-10234"
$message     = $null

function New-Result([string]$Status, [string]$Message) {
    @{ Status = $Status; Message = $Message } | ConvertTo-Json
}

# Hollyfield workbench bucket (hollyfield-workbench-<deploymentId>)
function Get-Workbench {
    $b = @(gcloud storage buckets list --project $projectname --format="value(name)" --filter="name~^hollyfield-workbench-" 2>$null) | Where-Object { $_ }
    if ($DeploymentId -and ($b -contains "hollyfield-workbench-$DeploymentId")) { return "hollyfield-workbench-$DeploymentId" }
    return ($b | Select-Object -First 1)
}

# URL of the core-banking API when its Cloud Run service is Ready, else $null
function Get-ServiceUrl {
    $json = gcloud run services describe $serviceName --region $region --project $projectname --format json 2>$null | Out-String
    if (-not $json.Trim()) { return $null }
    $svc = $json | ConvertFrom-Json
    $ready = @($svc.status.conditions | Where-Object { $_.type -eq "Ready" -and $_.status -eq "True" })
    if ($ready.Count -gt 0 -and $svc.status.url) { return $svc.status.url }
    return $null
}

# Holly's trace lines (log "holly-trace", written by the starter's callbacks). No quotes in the filter on purpose.
function Get-Trace([string]$Message, [int]$Minutes = 120) {
    $filter = "logName:holly-trace AND jsonPayload.message=$Message"
    $json = gcloud logging read $filter --project $projectname --freshness "$($Minutes)m" --limit 200 --order desc --format json 2>$null | Out-String
    Write-Host "Log query: $filter (last $Minutes min)"
    if (-not $json.Trim()) { return @() }
    return @($json | ConvertFrom-Json)
}

# Request lines written by the core-banking API on Cloud Run
function Get-ApiRequests([int]$Minutes = 120) {
    $filter = "resource.type=cloud_run_revision AND resource.labels.service_name=$serviceName AND jsonPayload.message=API_REQUEST"
    $json = gcloud logging read $filter --project $projectname --freshness "$($Minutes)m" --limit 300 --order desc --format json 2>$null | Out-String
    Write-Host "Log query: $filter (last $Minutes min)"
    if (-not $json.Trim()) { return @() }
    return @($json | ConvertFrom-Json)
}

function Get-Account($entry) {
    $a = $entry.jsonPayload.args
    if (-not $a) { return "" }
    $v = $a.account_id
    if (-not $v) { foreach ($p in $a.PSObject.Properties) { if ("$($p.Value)" -match '(?i)HB-\d{5}') { $v = "$($p.Value)" } } }
    return ("$v").Trim().ToUpper()
}

try {
    if (-not $projectname) { throw "The projectname parameter is empty. Map it to GET-GCP-PROJECT." }
    Write-Host "Project: $projectname | DeploymentId: $DeploymentId"
    gcloud config set project $projectname --quiet 2>$null | Out-Null

    $bench = Get-Workbench
    $code = if ($bench) { (gcloud storage cat "gs://$bench/app/holly/agent.py" --project $projectname 2>$null | Out-String) } else { "" }
    $reqs = if ($bench) { (gcloud storage cat "gs://$bench/app/holly/requirements.txt" --project $projectname 2>$null | Out-String) } else { "" }

    function Get-Docstring([string]$Code, [string]$Name) {
        $m = [regex]::Match($Code, '(?s)def\s+' + $Name + '\s*\([^)]*\)[^:\n]*:\s*[rRuU]?("""|'''''')(.*?)\1')
        if ($m.Success) { return $m.Groups[2].Value.Trim() }
        return $null
    }

    if (-not $code.Trim()) {
        $message = New-Result "Failed" "Holly's code was not found. Upload agent.py, __init__.py and requirements.txt to gs://$bench/app/holly."
    }
    elseif (-not $reqs.Trim()) {
        $message = New-Result "Failed" "requirements.txt is missing from gs://$bench/app/holly. Upload the whole holly folder."
    }
    else {
        $balanceDoc = Get-Docstring $code "get_account_balance"
        $ratesDoc   = Get-Docstring $code "get_savings_rates"
        $toolsList  = [regex]::Match($code, '(?s)tools\s*=\s*\[([^\]]*)\]').Groups[1].Value
        Write-Host "balance docstring: $(if ($balanceDoc) { $balanceDoc.Length } else { 0 }) chars | rates docstring: $(if ($ratesDoc) { $ratesDoc.Length } else { 0 }) chars | tools: $toolsList"

        if ($code -notmatch 'def\s+get_account_balance\s*\(' -or $code -notmatch 'def\s+get_savings_rates\s*\(') {
            $message = New-Result "Failed" "Holly's code must define get_account_balance and get_savings_rates."
        }
        elseif ($code -notmatch 'after_tool_callback\s*=\s*trace_tool_call' -or $code -notmatch 'after_model_callback\s*=\s*trace_answer' -or $code -notmatch 'on_tool_error_callback\s*=\s*trace_tool_crash') {
            $message = New-Result "Failed" "Holly's Elf trace callbacks were removed or changed. Put back the three callback lines from the starter file."
        }
        elseif (-not $balanceDoc -or $balanceDoc.Length -lt 80 -or $balanceDoc -notmatch 'account_id' -or $balanceDoc -notmatch '(?i)HB-') {
            $message = New-Result "Failed" "get_account_balance needs a fuller docstring: say when to use it and describe account_id, including its HB-12345 format."
        }
        elseif (-not $ratesDoc -or $ratesDoc.Length -lt 60) {
            $message = New-Result "Failed" "get_savings_rates needs a fuller docstring that tells Gemini when to use it."
        }
        elseif ($code -notmatch 'error_code') {
            $message = New-Result "Failed" "Holly's tools do not return an error_code. Follow Holly's tool contract for errors."
        }
        elseif ($code -match '812\.4|2450\.0|2,450') {
            $message = New-Result "Failed" "Holly's code contains a hard-coded balance. Every number must come from the core-banking API."
        }
        else {
            $message = New-Result "Succeeded" "Holly's balance and savings-rates tools are written: clear docstrings, the tool contract and the trace are in place, and no numbers are hard-coded."
        }
    }
}
catch {
    Write-Host "`nERROR:"
    Write-Host $_
    $message = New-Result "Failed" "The check could not finish. Please wait a minute and validate again. Details: $_"
}

Write-Host "`n=== FINAL RESPONSE ==="
Write-Host $message

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body       = $message
})
