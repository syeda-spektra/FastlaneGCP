<#
 CloudLabs validation | LAB02A-BONUS-TASK1
 Christmas Bonus: Interest by New Year   (0 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShell        Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - holly-trace: a tool whose name contains 'interest' returned status=success
     for a Hollyfield account (optional bonus)
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

    $calls = @(Get-Trace -Message "TOOL_CALL")
    $bonus = @($calls | Where-Object { "$($_.jsonPayload.tool)" -match '(?i)interest' -and $_.jsonPayload.status -eq "success" -and (Get-Account $_) -match '^HB-\d{5}$' })
    $tried = @($calls | Where-Object { "$($_.jsonPayload.tool)" -match '(?i)interest' })
    Write-Host "interest tool calls: $($tried.Count) | successful: $($bonus.Count)"
    if ($bonus.Count -gt 0) {
        $message = New-Result "Succeeded" "Christmas Bonus! Holly can now estimate the interest a customer will earn by New Year."
    }
    elseif ($tried.Count -gt 0) {
        $message = New-Result "Failed" "Holly called an interest tool, but it did not return status 'success' for a Hollyfield account."
    }
    else {
        $message = New-Result "Failed" "No interest tool in Holly's trace yet. Add a tool whose name contains 'interest', register it, and ask Holly how much interest $homeAccount will earn by New Year."
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
