param (
    [Parameter(Mandatory = $true)]
    [string]$URL
)

# Check if URL is supplied
if (-not $URL) {
    Write-Host "Error: The URL parameter is mandatory."
    exit
}

# Get the path to the YT-DLP executable
$YTDownloader = Join-Path $PSScriptRoot "yt-dlp.exe"

# Download a list of available formats for given video URL
Write-Host "Downloading list of available formats for this video..."
$formatsRaw = & "$YTDownloader" --no-warnings -F $URL | Select-Object -Skip 4

# Extract the relevant data into fields
$formats = $formatsRaw | ForEach-Object {
    if ($_ -match "^(?<ID>\d+)\s+(?<Ext>\w+)\s+(?<Resolution>\d+x\d+|\w+)\s+(?<Note>.*)$") {
        [pscustomobject]@{
            ID         = $Matches.ID
            Extension  = $Matches.Ext
            Resolution = $Matches.Resolution
            Note       = $Matches.Note
        }
    }
}

# Allow user to choose an audio and video format to download and merge
Write-Host "Select formats you wish to download and merge (one Audio & one Video)..."
$selectedFormats = $formats | Out-GridView -Title "Select Formats to Download" -PassThru 

# If the user clicked OK, check if any formats were selected
if ($selectedFormats) {
    # Join the formats with a "+"
    $selectedIDs = $selectedFormats.ID -join "+"
    Write-Host "You selected format IDs: $selectedIDs"
    # Download the formats and merge them
    Write-Host "Attempting to download and merge formats..."
    $output = & "$YTDownloader" --no-warnings -q --print after_move:filepath -f "$SelectedIDs" $URL
    # Display the full path to the downloaded video file
    $filename = ($out -split '`n')[-1]   #output has a number of lines. Get the last one for the actual filename.
    Write-Host "File saved to: " -NoNewLine
    Write-Host $filename -ForegroundColor Green
} else {
    Write-Host "No formats were selected."
}
