<# 

Retention policy:
PRIMARY (sqlbackups):
  - FULL:  if ageDays > FullMoveToCoolAfterDays AND ageDays <= FullDeleteAfterDays  => set tier to Cool
  - FULL:  if ageDays > FullDeleteAfterDays                                       => delete
  - DIFF:  if ageDays > DiffLogDeleteAfterDays                                    => delete
  - LOG:   if ageDays > DiffLogDeleteAfterDays                                    => delete

ARCHIVE (archive):
  - Any blob: if ageDays > ArchiveDeleteAfterDays                                 => delete
  - Any blob: otherwise                                                           => ensure tier is Cold (optional but enabled)

#>
param
(
  [Parameter(Mandatory = $false)]  [string] $StorageAccountName = "sauksprdsqlbackups",

  [Parameter(Mandatory = $false)] [string] $PrimaryContainerName = "sqlbackups",
  [Parameter(Mandatory = $false)] [string] $ArchiveContainerName = "archive",

  [Parameter(Mandatory = $false)] [string] $PrimaryRootPrefix = "",
  [Parameter(Mandatory = $false)] [string] $ArchiveRootPrefix = "Decommissioned/",

  [Parameter(Mandatory = $false)] [int] $FullMoveToCoolAfterDays = 14,
  [Parameter(Mandatory = $false)] [int] $FullDeleteAfterDays = 60,
  [Parameter(Mandatory = $false)] [int] $DiffLogDeleteAfterDays = 14,
  [Parameter(Mandatory = $false)] [int] $ArchiveDeleteAfterDays = 365,

  [Parameter(Mandatory = $false)] [ValidateSet("Hot", "Cool", "Cold")]
  [string] $FullTierAfterMove = "Cool",

  [Parameter(Mandatory = $false)] [ValidateSet("Hot", "Cool", "Cold")]
  [string] $ArchiveTier = "Cold",

  [Parameter(Mandatory = $false)] [bool] $DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log([string] $msg) {
  $ts = (Get-Date).ToUniversalTime().ToString("s") + "Z"
  Write-Output "[$ts] $msg"
}

function Get-BackupTypeFromName([string] $name) {
  $lower = $name.ToLowerInvariant()
  if ($lower -match "/full/") { return "full" }
  if ($lower -match "/diff/") { return "diff" }
  if ($lower -match "/log(s)?/") { return "log" }
  return "unknown"
}

function Get-AgeDaysUtc([object] $blob, [datetime] $nowUtc) {
  # Try common shapes for LastModified in different Az.Storage versions
  $lmRaw = $null

  if ($blob -and $blob.PSObject.Properties.Match('ICloudBlob').Count -gt 0 -and $blob.ICloudBlob) {
    $lmRaw = $blob.ICloudBlob.Properties.LastModified
  }
  if (-not $lmRaw -and $blob.PSObject.Properties.Match('BlobProperties').Count -gt 0 -and $blob.BlobProperties) {
    $lmRaw = $blob.BlobProperties.LastModified
  }
  if (-not $lmRaw -and $blob.PSObject.Properties.Match('Properties').Count -gt 0 -and $blob.Properties) {
    $lmRaw = $blob.Properties.LastModified
  }
  if (-not $lmRaw) { return 0 }

  if ($lmRaw -is [DateTime]) { 
    $lmUtc = $lmRaw.ToUniversalTime() 
  }
  elseif ($lmRaw -is [DateTimeOffset]) { 
    $lmUtc = $lmRaw.UtcDateTime 
  }
  else { 
    $lmUtc = ([DateTime]::Parse($lmRaw.ToString())).ToUniversalTime() 
  }

  return [int][Math]::Floor(($nowUtc - $lmUtc).TotalDays)
}

function Delete-Blob([object] $ctx, [string] $container, [string] $name, [bool] $dryRun) {
  if ($dryRun) { Write-Log "DRY-DELETE blob=$name"; return }
  Remove-AzStorageBlob -Context $ctx -Container $container -Blob $name -Force | Out-Null
  Write-Log "DELETED blob=$name"
}

function Tier-Blob([object] $ctx, [string] $container, [string] $name, [string] $tier, [bool] $dryRun) {
  if ($dryRun) { Write-Log "DRY-TIER blob=$name -> $tier"; return }

  # Get a blob reference in a reliable way
  $blobRef = $null
  try {
    $blobRef = Get-AzStorageBlob -Context $ctx -Container $container -Blob $name -ErrorAction Stop
  }
  catch {
    Write-Log "ERROR tier: cannot get blob reference blob=$name msg=$($_.Exception.Message)"
    return
  }

  # In some Az.Storage shapes, the actual SDK blob is in ICloudBlob
  $cloudBlob = $null
  if ($blobRef -and $blobRef.PSObject.Properties.Match('ICloudBlob').Count -gt 0 -and $blobRef.ICloudBlob) {
    $cloudBlob = $blobRef.ICloudBlob
  }
  elseif ($blobRef -and $blobRef.PSObject.Properties.Match('CloudBlob').Count -gt 0 -and $blobRef.CloudBlob) {
    $cloudBlob = $blobRef.CloudBlob
  }
  elseif ($blobRef -and $blobRef.PSObject.Properties.Match('CloudBlockBlob').Count -gt 0 -and $blobRef.CloudBlockBlob) {
    $cloudBlob = $blobRef.CloudBlockBlob
  }

  if (-not $cloudBlob) {
    Write-Log "ERROR tier: ICloudBlob not available blob=$name (module shape)."
    return
  }

  try {
    # Ensure properties are loaded
    $cloudBlob.FetchAttributes()

    # Convert tier string to the proper enum when possible
    $tierEnum = $tier
    try {
      $tierEnum = [Microsoft.WindowsAzure.Storage.Blob.StandardBlobTier]::$tier
    }
    catch {
      # keep as string if enum not available; some runtime versions accept string
      $tierEnum = $tier
    }

    $cloudBlob.SetStandardBlobTier($tierEnum)
    Write-Log "TIERED blob=$name -> $tier"
  }
  catch {
    Write-Log "ERROR tier: blob=$name tier=$tier msg=$($_.Exception.Message)"
  }
}

function Sweep-Primary([object] $ctx, [string] $container, [string] $prefix, [datetime] $nowUtc) {
  Write-Log "PRIMARY SWEEP start container=$container prefix=$prefix"

  $blobs = @(Get-AzStorageBlob -Context $ctx -Container $container -Prefix $prefix)
  foreach ($b in $blobs) {
    if (-not $b.Name -or $b.Name.EndsWith("/")) { continue }

    $age = Get-AgeDaysUtc $b $nowUtc
    $type = Get-BackupTypeFromName $b.Name

    if ($type -eq "unknown") {
      Write-Log "SKIP-UNKNOWN ageDays=$age blob=$($b.Name)"
      continue
    }

    if ($type -eq "full") {
      if ($age -gt $FullDeleteAfterDays) {
        Delete-Blob $ctx $container $b.Name $DryRun
      }
      elseif ($age -gt $FullMoveToCoolAfterDays) {
        Tier-Blob $ctx $container $b.Name $FullTierAfterMove $DryRun
      }
      else {
        Write-Log "KEEP-FULL ageDays=$age blob=$($b.Name)"
      }
      continue
    }

    # diff/log
    if ($age -gt $DiffLogDeleteAfterDays) {
      Delete-Blob $ctx $container $b.Name $DryRun
    } 
    else {
      Write-Log "KEEP-$type ageDays=$age blob=$($b.Name)"
    }
  }

  Write-Log "PRIMARY SWEEP end"
}

function Sweep-Archive([object] $ctx, [string] $container, [string] $prefix, [datetime] $nowUtc) {
  Write-Log "ARCHIVE SWEEP start container=$container prefix=$prefix"

  $blobs = @(Get-AzStorageBlob -Context $ctx -Container $container -Prefix $prefix)
  foreach ($b in $blobs) {
    if (-not $b.Name -or $b.Name.EndsWith("/")) { continue }

    $age = Get-AgeDaysUtc $b $nowUtc

    if ($age -gt $ArchiveDeleteAfterDays) {
      Delete-Blob $ctx $container $b.Name $DryRun
    } 
    else {
      # optional: enforce Cold for anything retained
      Tier-Blob $ctx $container $b.Name $ArchiveTier $DryRun
    }
  }

  Write-Log "ARCHIVE SWEEP end"
}

# ---- MAIN ----
$nowUtc = (Get-Date).ToUniversalTime()
Write-Log "Starting run storageAccount=$StorageAccountName DryRun=$DryRun"

Connect-AzAccount -Identity | Out-Null
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

# Run sweeps
Sweep-Primary -ctx $ctx -container $PrimaryContainerName -prefix $PrimaryRootPrefix -nowUtc $nowUtc
Sweep-Archive -ctx $ctx -container $ArchiveContainerName -prefix $ArchiveRootPrefix -nowUtc $nowUtc

Write-Log "Done."