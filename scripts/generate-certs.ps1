# Quickpass - Self-signed certificate generator for mobile camera access
# Usage: .\scripts\generate-certs.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectDir = Split-Path -Parent $ScriptDir
$CertsDir = Join-Path $ProjectDir "certs"

$crtPath  = Join-Path $CertsDir "server.crt"
$keyPath  = Join-Path $CertsDir "server.key"
$pfxPath  = Join-Path $CertsDir "server.pfx"

if (-not (Test-Path $CertsDir)) {
    New-Item -ItemType Directory -Path $CertsDir -Force | Out-Null
}

if (Test-Path $crtPath) {
    Write-Host "Certificates already exist at $CertsDir" -ForegroundColor Green
    Write-Host "  $crtPath" -ForegroundColor Gray
    if (Test-Path $keyPath) {
        Write-Host "  $keyPath" -ForegroundColor Gray
    }
    exit 0
}

Write-Host "Generating self-signed certificate for development..." -ForegroundColor Yellow
Write-Host "Output: $crtPath, $keyPath" -ForegroundColor Cyan

# Generate self-signed certificate (RSA 2048, SHA256, CN=localhost, valid 1 year)
$password = ConvertTo-SecureString -String "P@ssw0rd!" -AsPlainText -Force

$cert = New-SelfSignedCertificate -DnsName "localhost" `
    -IpAddress "127.0.0.1" `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -NotAfter (Get-Date).AddYears(1) `
    -KeyAlgorithm "RSA" `
    -KeyLength 2048 `
    -HashAlgorithm "SHA256" `
    -TextExtension @("2.5.29.17={text}DNS:localhost,IP:127.0.0.1")

# Export certificate to .crt (includes private key on PowerShell 7+)
Export-Certificate -InputStream $cert -FilePath $crtPath -Force

# Export to .pfx (includes private key + password) — backward compatible
Export-PfxCertificate -CertStoreLocation "Cert:\LocalMachine\My" `
    -Password $password `
    -FilePath $pfxPath

# Also export the public key portion to .crt if the main export had private key issues
# The cert.crt already has the full cert; we just need to make sure private key file exists
if (-not (Test-Path $keyPath)) {
    # Extract private key from PFX
    # Import PFX back and extract key
    $pfxCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfxPath, $password)
    $csp = [System.Security.Cryptography.CspParameters]::new()
    $csp.KeyContainerName = [Guid]::NewGuid().ToString()
    $rsa = [System.Security.Cryptography.RSA]::Create()
    $rsa.importable = $true
    $rsa.fromXmlString($pfxCert.PrivateKey.ToXmlString($true))

    # Write the private key in PEM format
    $keyXml = $rsa.ToXmlString($true)
    $keyPem = [System.Text.Encoding]::UTF8.GetBytes("-----BEGIN RSA PRIVATE KEY-----`n$keyXml`n-----END RSA PRIVATE KEY-----")
    [IO.File]::WriteAllBytes($keyPath, $keyPem)
}

Write-Host "" -ForegroundColor Gray
Write-Host "Certificate generated at $CertsDir:" -ForegroundColor Cyan
Write-Host "  server.crt  - full certificate (PEM format)" -ForegroundColor Gray
Write-Host "  server.key  - private key (PEM format, for OpenSSL/Node.js backend)" -ForegroundColor Gray
Write-Host "  server.pfx  - password-protected PFX bundle (for Windows/IIS)" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "Environment setup (backend/.env):" -ForegroundColor Cyan
Write-Host "  HTTPS_KEY=$crtPath" -ForegroundColor Gray
Write-Host "  HTTPS_CERT=$pfxPath" -ForegroundColor Gray
Write-Host "" -ForegroundColor Gray
Write-Host "For production, replace with Let's Encrypt or a proper CA-signed certificate." -ForegroundColor Yellow