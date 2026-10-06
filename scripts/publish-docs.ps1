# Build the documentation site and publish it to the VM.
#
#   .\scripts\publish-docs.ps1
#   .\scripts\publish-docs.ps1 -Key "C:\path\to\vps.key"
#
# Served at https://staging.goldenbook.in/docs/ behind that host's basic auth (see the staging
# block in tradestack/deploy/Caddyfile). The docs describe operations and known gaps, so they
# are never published to the public host.
#
# Needs the docs virtualenv (see docs/contributing.md): .venv-docs with requirements-docs.txt.
# The build is strict, so a broken link or a page missing from the navigation stops it before
# anything is uploaded.
param(
    [string]$Key = (Join-Path $HOME '.ssh\vps.key'),
    [string]$Server = 'ubuntu@140.245.250.217'
)

# Native tools (mkdocs, tar, scp, ssh) write progress to stderr, which Windows PowerShell 5.1 turns
# into a terminating error under 'Stop'. Every native call below checks $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
$mkdocs = Join-Path $root '.venv-docs\Scripts\mkdocs.exe'

if (-not (Test-Path -LiteralPath $Key -PathType Leaf)) { throw "SSH key not found: $Key" }
if (-not (Test-Path -LiteralPath $mkdocs -PathType Leaf)) {
    throw "mkdocs not found at $mkdocs. Create the virtualenv first: see docs/contributing.md"
}

Push-Location $root
try {
    Write-Host '==> Building (strict)'
    & $mkdocs build --strict
    if ($LASTEXITCODE -ne 0) { throw "mkdocs build failed with exit code $LASTEXITCODE" }

    $archive = Join-Path ([IO.Path]::GetTempPath()) 'goldenbook-docs.tar.gz'
    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
    & tar -czf $archive -C (Join-Path $root 'site') .
    if ($LASTEXITCODE -ne 0) { throw "tar failed with exit code $LASTEXITCODE" }

    Write-Host '==> Uploading'
    & scp -q -i $Key $archive "${Server}:/tmp/goldenbook-docs.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw "scp failed with exit code $LASTEXITCODE" }

    # Extract beside the live directory, then swap, so a request never sees a half-written site.
    $remote = @'
set -e
NEW=/var/www/goldenbook-docs.new
sudo rm -rf "$NEW" && sudo mkdir -p "$NEW"
sudo tar -xzf /tmp/goldenbook-docs.tar.gz -C "$NEW"
sudo chmod -R a+rX "$NEW"
sudo rm -rf /var/www/goldenbook-docs.old
if [ -d /var/www/goldenbook-docs ]; then sudo mv /var/www/goldenbook-docs /var/www/goldenbook-docs.old; fi
sudo mv "$NEW" /var/www/goldenbook-docs
sudo rm -rf /var/www/goldenbook-docs.old /tmp/goldenbook-docs.tar.gz
echo "published $(sudo find /var/www/goldenbook-docs -name '*.html' | wc -l) pages"
'@
    & ssh -i $Key $Server ($remote -replace "`r", '')
    if ($LASTEXITCODE -ne 0) { throw "publish failed with exit code $LASTEXITCODE" }
    Write-Host '==> Done: https://staging.goldenbook.in/docs/'
}
finally {
    Pop-Location
}
