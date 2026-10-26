<#
 CloudLabs validation | LAB02A-EX2-TASK1
 Explore the Core-Banking API   (10 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - Cloud Run request logs of hollyfield-core-banking (last 120 min) show:
     GET /v1/savings/rates (200), GET /v1/accounts/HB-xxxxx/balance (200)
     and a 404 for an unknown account
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

    $url = Get-ServiceUrl
    if (-not $url) {
        $message = New-Result "Failed" "The core-banking API is not live yet. Validate the 'Prepare Hollyfield' task first."
    }
    else {
        $requests = @(Get-ApiRequests -Minutes 120)
        $rates = @($requests | Where-Object { $_.jsonPayload.path -eq "/v1/savings/rates" -and [int]$_.jsonPayload.status -eq 200 })
        $balances = @($requests | Where-Object { $_.jsonPayload.path -match '(?i)^/v1/accounts/HB-\d{5}/balance$' -and [int]$_.jsonPayload.status -eq 200 })
        $missing = @($requests | Where-Object { [int]$_.jsonPayload.status -eq 404 -and $_.jsonPayload.path -match '(?i)^/v1/accounts/' })
        Write-Host "API requests: $($requests.Count) | rates 200: $($rates.Count) | balance 200: $($balances.Count) | account 404: $($missing.Count)"
        if ($requests.Count -eq 0) {
            $message = New-Result "Failed" "No requests have reached the core-banking API yet. Call its endpoints from Cloud Shell, wait 1 minute, then validate again."
        }
        elseif ($rates.Count -eq 0) {
            $message = New-Result "Failed" "You have not read the savings rates yet. Call the rates endpoint, wait 1 minute, then validate again."
        }
        elseif ($balances.Count -eq 0) {
            $message = New-Result "Failed" "You have not read an account balance yet. Call the balance endpoint for a real Hollyfield account, wait 1 minute, then validate again."
        }
        elseif ($missing.Count -eq 0) {
            $message = New-Result "Failed" "You have not seen how the API reports an unknown account yet. Ask for the balance of an account that does not exist, wait 1 minute, then validate again."
        }
        else {
            $message = New-Result "Succeeded" "You explored the core-banking API: rates, a balance and an unknown account."
        }
    }
}
catch {
    Write-Host "`nERROR:"
    Write-Host $_
    $message = New-Result "Failed" "The elves could not finish the check. Please wait a minute and validate again. Details: $_"
}

Write-Host "`n=== FINAL RESPONSE ==="
Write-Host $message

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body       = $message
})
