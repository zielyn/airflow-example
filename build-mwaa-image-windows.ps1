param(
  [switch]$NormalizeOnly
)

$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $RootDir '.env'
$EnvExampleFile = Join-Path $RootDir '.env.example'

function Get-EnvVarFromFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Key,
    [Parameter(Mandatory = $true)]
    [string]$DefaultValue
  )

  $sourceFile = $null
  if (Test-Path $EnvFile) {
    $sourceFile = $EnvFile
  } elseif (Test-Path $EnvExampleFile) {
    $sourceFile = $EnvExampleFile
  }

  if (-not $sourceFile) {
    return $DefaultValue
  }

  $line = Select-String -Path $sourceFile -Pattern "^$Key=" | Select-Object -Last 1
  if (-not $line) {
    return $DefaultValue
  }

  $value = $line.Line.Substring($Key.Length + 1)
  $value = $value.Trim()
  $value = $value.Trim('"')
  $value = $value.Trim("`r")

  if ([string]::IsNullOrWhiteSpace($value)) {
    return $DefaultValue
  }

  return $value
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw 'docker is required in PATH.'
}

$AirflowVersion = Get-EnvVarFromFile -Key 'AIRFLOW_VERSION' -DefaultValue '3.0.6'
$MwaaImageRepository = Get-EnvVarFromFile -Key 'MWAA_IMAGE_REPOSITORY' -DefaultValue 'amazon-mwaa-docker-images/airflow'

$ImageDir = Join-Path $RootDir "st/amazon-mwaa-docker-images/images/airflow/$AirflowVersion"
$BaseDockerfile = Join-Path $ImageDir 'Dockerfiles/Dockerfile.base'
$DevDockerfile = Join-Path $ImageDir 'Dockerfiles/Dockerfile-dev'

if (-not (Test-Path $ImageDir)) {
  Write-Error "Missing subtree Airflow version directory: $ImageDir"
  Write-Output 'Available versions under subtree:'
  Get-ChildItem -Path (Join-Path $RootDir 'st/amazon-mwaa-docker-images/images/airflow') -Directory |
    Sort-Object Name |
    ForEach-Object { "  - $($_.Name)" }
  Write-Output 'Tip: check AIRFLOW_VERSION in .env for hidden CRLF or quotes.'
  exit 1
}

if (-not (Test-Path $BaseDockerfile) -or -not (Test-Path $DevDockerfile)) {
  Write-Error "Expected Dockerfiles were not found under $ImageDir/Dockerfiles"
  Write-Output 'Ensure the subtree is present and includes generated Dockerfiles.'
  exit 1
}

function Normalize-LineEndings {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir
  )

  $targets = Get-ChildItem -Path $TargetDir -Recurse -File | Where-Object {
    $_.Name -like '*.sh' -or
    $_.Name -eq 'build.sh' -or
    $_.Name -eq 'run.sh' -or
    $_.Name -eq 'temporary-pip-install' -or
    $_.FullName -match '[\\/]bin[\\/]' -or
    $_.FullName -match '[\\/]bootstrap[\\/]' -or
    $_.FullName -match '[\\/]bootstrap-dev[\\/]'
  }

  foreach ($file in $targets) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $normalized = $content -replace "`r`n", "`n"
    if ($normalized -ne $content) {
      [System.IO.File]::WriteAllText(
        $file.FullName,
        $normalized,
        [System.Text.UTF8Encoding]::new($false)
      )
    }
  }
}

Write-Output "Normalizing script line endings under $ImageDir"
Normalize-LineEndings -TargetDir $ImageDir

if ($NormalizeOnly) {
  Write-Output 'Normalization complete (no image build requested).'
  exit 0
}

Write-Output "Building ${MwaaImageRepository}:${AirflowVersion}-base"
& docker build `
  -f $BaseDockerfile `
  -t "${MwaaImageRepository}:${AirflowVersion}-base" `
  $ImageDir

Write-Output "Building ${MwaaImageRepository}:${AirflowVersion}-dev"
& docker build `
  -f $DevDockerfile `
  -t "${MwaaImageRepository}:${AirflowVersion}-dev" `
  $ImageDir

Write-Output 'MWAA image build complete.'
Write-Output 'Next: docker compose --env-file .env -f docker/docker-compose-local.yml up -d'
