param(
    [Parameter(Mandatory=$true)]
    [string]$serviceNameInSDK
)

$specsRepoRoot = git rev-parse --show-toplevel
$sdkRepoRoot = Resolve-Path (Join-Path $specsRepoRoot ".." "azure-sdk-for-net")

$serviceFolder = Join-Path $sdkRepoRoot "sdk" $serviceNameInSDK
if (-not (Test-Path $serviceFolder)) {
    Write-Error "Service folder not found: $serviceFolder"
    exit 1
}

$resourceManagerFolders = Get-ChildItem -Path $serviceFolder -Directory | 
    Where-Object { $_.Name -like "Azure.ResourceManager*" }

if ($resourceManagerFolders.Count -eq 0) {
    Write-Host "No Azure.ResourceManager folders found under $serviceFolder"
    exit 0
}
if ($resourceManagerFolders.Count -gt 1) {
    Write-Host "Multiple Azure.ResourceManager folders found under $serviceFolder"
    exit 0
}

$autorestMd = Join-Path $resourceManagerFolders[0].FullName "src" "autorest.md"
if (-not (Test-Path $autorestMd)) {
    Write-Host "autorest.md not found under $($resourceManagerFolders[0].FullName)"
    exit 0
}

$content = Get-Content -Path $autorestMd
# Check if the file contains 'require' field and extract the commit ID and folder name
$requireFound = $false
foreach ($line in $content) {
    if ($line -match "require:\s*(https://github.com/Azure/azure-rest-api-specs/(?:blob|tree)/([a-f0-9]+)/specification/([^/]+)/.*)") {
        $requireValue = $matches[1]
        $commitId = $matches[2]
        $folderName = $matches[3]
        Write-Output "File: $autorestMd"
        Write-Output "Require: $requireValue"
        Write-Output "Commit ID: $commitId"
        Write-Output "Folder Name: $folderName"
        Write-Output ""
        $requireFound = $true
        break
    }
}

# If the file does not contain 'require' field or commit ID, report an error
if (-not $requireFound) {
    Write-Error "File: $autorestMd does not contain a valid 'require' field or commit ID."
    break
}   

$newSwaggerMdPath = Join-Path $specsRepoRoot "specification" $folderName "resource-manager" "readme.md"
$tagInSwaggerMd = Get-Content -Path $newSwaggerMdPath | Select-String -Pattern "^tag: "
if ($tagInSwaggerMd.Count -gt 1) {
    throw "There are multiple tags in the readme file. Please remove the extra ones"
}
$tagInSwaggerMd = $tagInSwaggerMd[0].ToString().Split(": ")[1]
$newTagValue = "tag: $tagInSwaggerMd"

# Step 1: Change the tag in the autorest.md file to match the tag in the readme file
# and change the commit id to the latest commit id in the main branch
(Get-Content -Path $autorestMd) -replace "^tag:.*", $newTagValue | Set-Content -Path $autorestMd

$latestCommitId = git ls-remote origin main | Select-String -Pattern "refs/heads/main" | ForEach-Object { $_.ToString().Split("`t")[0] }
$newRequireValue = "require: $($requireValue.Replace($commitId, $latestCommitId))"
(Get-Content -Path $autorestMd) -replace "require:.*", $newRequireValue | Set-Content -Path $autorestMd

# Go to the folder that holds the autorest.md file and run the dotnet build command
$autorestMdFolder = Split-Path -Path $autorestMd -Parent
Push-Location $autorestMdFolder
try {
    Write-Host "Running dotnet build /t:GenerateCode in $autorestMdFolder"
    dotnet build /t:GenerateCode
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
catch {
    Write-Error "An error occurred during the dotnet build process: $_"
}
finally {
    Pop-Location
}

Push-Location $sdkRepoRoot
try {
    Write-Host "Exporting API"
    .\eng\scripts\Export-API.ps1 $serviceNameInSDK
    if ($LASTEXITCODE) { exit $LASTEXITCODE }

    Write-Host "Running git add"
    git add $resourceManagerFolders[0]
}
catch {
    Write-Error "An error occurred during the dotnet build process: $_"
}
finally {
    Pop-Location
}

# Step 2: Change the require in the autorest.md file to point to the new readme file
$newRequireValue = "require: $newSwaggerMdPath"
(Get-Content -Path $autorestMd) -replace "require:.*", $newRequireValue | Set-Content -Path $autorestMd
Push-Location $autorestMdFolder
try {
    Write-Host "Running dotnet build /t:GenerateCode in $autorestMdFolder"
    dotnet build /t:GenerateCode
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
catch {
    Write-Error "An error occurred during the dotnet build process: $_"
}
finally {
    Pop-Location
}

Push-Location $sdkRepoRoot
try {
    Write-Host "Exporting API"
    .\eng\scripts\Export-API.ps1 $serviceNameInSDK
    if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
catch {
    Write-Error "An error occurred during the dotnet build process: $_"
}
finally {
    Pop-Location
}