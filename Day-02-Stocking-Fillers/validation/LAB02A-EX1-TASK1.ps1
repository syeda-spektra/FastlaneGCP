<#
 CloudLabs validation | LAB02A-EX1-TASK1
 Prepare Hollyfield   (5 points)
 Lab: Day 2 - Stocking Fillers (Track A: Developer, Challenge)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID (System)
               projectname  = GET-GCP-PROJECT   (System)

 Passes when:
   - Hollyfield services on, Artifact Registry repo + builder permissions in place,
     core-banking API built (Cloud Build) and Ready on Cloud Run (safe to run again;
     waits up to 150 s, then asks the learner to validate again)
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

    $builderSa = "hollyfield-builder@$projectname.iam.gserviceaccount.com"
    $runtimeSa = "core-banking-sa@$projectname.iam.gserviceaccount.com"
    $apiRepo   = "https://raw.githubusercontent.com/syeda-spektra/FastlaneGCP/refs/heads/main/Day-02-Stocking-Fillers/core-banking-api"
    $failed    = @()

    Write-Host "[1/6] Turning on Service Usage, then the Hollyfield services"
    gcloud services enable serviceusage.googleapis.com --project $projectname --quiet 2>&1 | Write-Host
    $apis = @("run.googleapis.com", "cloudbuild.googleapis.com", "artifactregistry.googleapis.com", "aiplatform.googleapis.com",
              "logging.googleapis.com", "storage.googleapis.com", "iam.googleapis.com", "cloudresourcemanager.googleapis.com",
              "compute.googleapis.com", "cloudtrace.googleapis.com")
    gcloud services enable $apis --project $projectname --quiet 2>&1 | Write-Host
    if ($LASTEXITCODE -ne 0) { $failed += "Google Cloud services" }

    $bench = Get-Workbench
    $url = Get-ServiceUrl
    if (-not $bench) {
        $message = New-Result "Failed" "The Hollyfield workbench bucket (hollyfield-workbench-*) was not found. The lab deployment may still be running. Please validate again in a minute."
    }
    elseif ($url) {
        Write-Host "Core-banking API already live: $url"
        $message = New-Result "Succeeded" "Hollyfield is ready. The core-banking API is live at $url"
    }
    elseif ($failed.Count -gt 0) {
        $message = New-Result "Failed" "Hollyfield is not ready yet: could not turn on $($failed -join ', '). Please validate again in a minute."
    }
    else {
        Write-Host "[2/6] Artifact Registry repository 'hollyfield'"
        gcloud artifacts repositories describe hollyfield --location $region --project $projectname --format="value(name)" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            gcloud artifacts repositories create hollyfield --repository-format docker --location $region --project $projectname --description "Hollyfield core-banking images" --quiet 2>&1 | Write-Host
            if ($LASTEXITCODE -ne 0) { $failed += "Artifact Registry repository" }
        }

        Write-Host "[3/6] Builder permissions (least privilege)"
        foreach ($role in @("roles/run.admin", "roles/artifactregistry.writer", "roles/logging.logWriter", "roles/storage.objectViewer")) {
            gcloud projects add-iam-policy-binding $projectname --member "serviceAccount:$builderSa" --role $role --condition=None --quiet 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { $failed += $role }
        }
        gcloud iam service-accounts add-iam-policy-binding $runtimeSa --member "serviceAccount:$builderSa" --role "roles/iam.serviceAccountUser" --project $projectname --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $failed += "builder may act as core-banking-sa" }

        Write-Host "[4/6] Is a build already running?"
        $ongoing = @(gcloud builds list --project $projectname --region $region --ongoing --filter="tags=hollyfield-core-banking" --format="value(id)" 2>$null) | Where-Object { $_ }

        if ($failed.Count -gt 0) {
            $message = New-Result "Failed" ("Hollyfield is not ready yet: " + ($failed -join ", ") + ". Please validate again in a minute.")
        }
        else {
            if ($ongoing.Count -eq 0) {
                Write-Host "[5/6] Building and deploying the core-banking API"
                $src = Join-Path ([IO.Path]::GetTempPath()) ("core-banking-" + [guid]::NewGuid().ToString("N"))
                New-Item -ItemType Directory -Path $src -Force | Out-Null
                foreach ($f in @("main.py", "core-banking-data.json", "requirements.txt", "Dockerfile", "cloudbuild.yaml")) {
                    Invoke-WebRequest -UseBasicParsing -Uri "$apiRepo/$f" -OutFile (Join-Path $src $f)
                }
                gcloud builds submit $src --project $projectname --region $region --config (Join-Path $src "cloudbuild.yaml") `
                    --service-account "projects/$projectname/serviceAccounts/$builderSa" `
                    --gcs-source-staging-dir "gs://$bench/cloudbuild-source" `
                    --substitutions "_REGION=$region" --async --quiet 2>&1 | Write-Host
            }
            else {
                Write-Host "[5/6] Build $($ongoing[0]) is already running"
            }

            Write-Host "[6/6] Waiting up to 150 seconds for the API"
            for ($i = 0; $i -lt 10 -and -not $url; $i++) {
                Start-Sleep -Seconds 15
                $url = Get-ServiceUrl
            }
            if ($url) {
                $message = New-Result "Succeeded" "Hollyfield is ready. The core-banking API is live at $url"
            }
            else {
                $last = @(gcloud builds list --project $projectname --region $region --filter="tags=hollyfield-core-banking" --sort-by="~createTime" --limit 1 --format="value(id,status)" 2>$null) | Select-Object -First 1
                Write-Host "Latest build: $last"
                if ("$last" -match "FAILURE|TIMEOUT|INTERNAL_ERROR|CANCELLED") {
                    $message = New-Result "Failed" "The core-banking API build did not finish ($last). Please validate again: the elves will rebuild it."
                }
                else {
                    $message = New-Result "Failed" "The elves are still building the core-banking API (about 3-4 minutes the first time). Please wait 2 minutes and validate again."
                }
            }
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
