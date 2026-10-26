<#
 CloudLabs validation | LAB02A-EX4-TASK1
 Task 4: Holly Handles an Unknown Account   (19 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShell        Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - holly-trace: get_account_balance returned status=error, error_code=ACCOUNT_NOT_FOUND
     for an unknown account (no exception) and Holly's reply in that turn has no money amount
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
    $known   = @("HB-10234", "HB-20419", "HB-31877")

    $notFound = @($calls | Where-Object { $_.jsonPayload.tool -eq "get_account_balance" -and $_.jsonPayload.status -eq "error" -and $_.jsonPayload.error_code -eq "ACCOUNT_NOT_FOUND" -and $known -notcontains (Get-Account $_) })
    $crashed  = @($crashes | Where-Object { $_.jsonPayload.tool -eq "get_account_balance" })
    $noStatus = @($calls | Where-Object { $_.jsonPayload.tool -eq "get_account_balance" -and $_.jsonPayload.status -notin @("success", "error") })
    Write-Host "handled ACCOUNT_NOT_FOUND: $($notFound.Count) | crashes: $($crashed.Count) | calls without a contract status: $($noStatus.Count)"

    if ($notFound.Count -eq 0) {
        if ($crashed.Count -gt 0) {
            $message = New-Result "Failed" "get_account_balance raised an exception for an unknown account (see TOOL_CRASH in holly-trace). A tool must return an error dict, never raise."
        }
        elseif ($noStatus.Count -gt 0) {
            $message = New-Result "Failed" "get_account_balance returned a result without a 'status' of 'success' or 'error'. Follow Holly's tool contract."
        }
        else {
            $message = New-Result "Failed" "Holly's trace shows no handled unknown account. Ask Holly for the balance of an account that does not exist; the tool must return status 'error' with error_code 'ACCOUNT_NOT_FOUND'."
        }
    }
    else {
        $ids = @($notFound | ForEach-Object { $_.jsonPayload.invocation_id })
        $replies = @($answers | Where-Object { $ids -contains $_.jsonPayload.invocation_id })
        $kind = @($replies | Where-Object { "$($_.jsonPayload.text)" -notmatch '\u00A3\s?\d[\d,]*\.\d{2}' })
        Write-Host "replies to unknown-account turns: $($replies.Count) | without an amount: $($kind.Count)"
        if ($replies.Count -eq 0) {
            $message = New-Result "Failed" "The tool handled the unknown account, but Holly never replied to the customer. Ask again and let Holly finish her answer."
        }
        elseif ($kind.Count -eq 0) {
            $message = New-Result "Failed" "For an unknown account Holly still quoted a money amount. Update her instruction so she never gives an amount when an account can't be found."
        }
        else {
            $message = New-Result "Succeeded" "Holly handles an unknown account kindly: the tool returned ACCOUNT_NOT_FOUND and she gave no made-up amount."
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
