<#
 CloudLabs validation | LAB02A-EX3-TASK1
 Task 3: Holly Uses Both Tools   (30 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShell        Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - holly-trace (last 120 min): get_account_balance succeeded for HB-10234,
     get_savings_rates succeeded, both were used in ONE turn (same invocation_id),
     and an answer quotes the Christmas Saver rate (4.10 %)
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

    $calls   = @(Get-Trace -Message "TOOL_CALL")
    $answers = @(Get-Trace -Message "AGENT_ANSWER")
    $crashes = @(Get-Trace -Message "TOOL_CRASH")
    Write-Host "TOOL_CALL: $($calls.Count) | AGENT_ANSWER: $($answers.Count) | TOOL_CRASH: $($crashes.Count)"

    $balanceOk = @($calls | Where-Object { $_.jsonPayload.tool -eq "get_account_balance" -and $_.jsonPayload.status -eq "success" -and (Get-Account $_) -eq $homeAccount })
    $ratesOk   = @($calls | Where-Object { $_.jsonPayload.tool -eq "get_savings_rates" -and $_.jsonPayload.status -eq "success" })
    $balanceIds = @($balanceOk | ForEach-Object { $_.jsonPayload.invocation_id })
    $bothIds    = @($ratesOk | Where-Object { $balanceIds -contains $_.jsonPayload.invocation_id } | ForEach-Object { $_.jsonPayload.invocation_id })
    $rateAnswer = @($answers | Where-Object { "$($_.jsonPayload.text)" -match '4\.10?\s*%' })
    Write-Host "balance($homeAccount) ok: $($balanceOk.Count) | rates ok: $($ratesOk.Count) | both in one turn: $($bothIds.Count) | answers with 4.10%: $($rateAnswer.Count)"

    if ($calls.Count -eq 0 -and $crashes.Count -eq 0) {
        $message = New-Result "Failed" "Holly has not called any tools yet. Check that her tools are registered and that holly/.env is set, ask her the customer questions, wait 1 minute, then validate again."
    }
    elseif ($balanceOk.Count -eq 0) {
        $tried = @($calls | Where-Object { $_.jsonPayload.tool -eq "get_account_balance" })
        if ($tried.Count -gt 0) {
            $message = New-Result "Failed" "Holly called get_account_balance, but never successfully for account $homeAccount. Ask for the Christmas Saver balance of $homeAccount and make sure the tool returns status 'success'."
        }
        else {
            $message = New-Result "Failed" "There is no get_account_balance call in Holly's trace. Name the tool exactly get_account_balance, register it, and ask for the balance of $homeAccount."
        }
    }
    elseif ($ratesOk.Count -eq 0) {
        $message = New-Result "Failed" "There is no successful get_savings_rates call in Holly's trace. Name the tool exactly get_savings_rates, register it, and ask Holly about savings rates."
    }
    elseif ($bothIds.Count -eq 0) {
        $message = New-Result "Failed" "Holly has never used both tools to answer ONE question. Ask a single question that needs a balance and a rate for $homeAccount."
    }
    elseif ($rateAnswer.Count -eq 0) {
        $message = New-Result "Failed" "Holly called her tools, but none of her answers quotes the Christmas Saver rate from the API. Ask her what the Christmas Saver pays."
    }
    else {
        $message = New-Result "Succeeded" "Holly's stocking is filled: she looked up $homeAccount, read the live savings rates and combined both in one answer."
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
