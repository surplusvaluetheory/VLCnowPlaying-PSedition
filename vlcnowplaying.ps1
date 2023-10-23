# Don't forget to set the execution policy.
# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
# This one is very permissive when run as administrator:
# set-executionpolicy remotesigned
# or run this as current user:
# Set-ExecutionPolicy -Scope CurrentUser remotesigned

# Load environment variables from .env file
Get-Content .env | ForEach-Object {
    $keyValue = $_ -split "="
    if ($keyValue[0] -and $keyValue[1]) {
        [System.Environment]::SetEnvironmentVariable($keyValue[0], $keyValue[1], [System.EnvironmentVariableTarget]::Process)
    }
}

# Read commands from .env
$commands = [System.Environment]::GetEnvironmentVariable('COMMANDS') -split ","


# Function to fetch current song and time information from VLC
Function Get-CurrentlyPlayingVLC {
    try {
        $VlcPassword = [System.Environment]::GetEnvironmentVariable('VLC_PASSWORD')
        $response = Invoke-RestMethod -Uri "http://localhost:8080/requests/status.json" -Headers @{Authorization=("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":{0}" -f $VlcPassword))))}
        
        $timeInSeconds = $response.time
        $lengthInSeconds = $response.length

        # Convert time to hh:mm:ss format
        $time = [TimeSpan]::FromSeconds($timeInSeconds)
        $length = [TimeSpan]::FromSeconds($lengthInSeconds)

        $timeStr = "{0:D2}:{1:D2}" -f $time.Minutes, $time.Seconds
        $lengthStr = "{0:D2}:{1:D2}" -f $length.Minutes, $length.Seconds

        # Include hours if greater than 0
        if ($time.Hours -gt 0) { $timeStr = "{0:D2}:{1}" -f $time.Hours, $timeStr }
        if ($length.Hours -gt 0) { $lengthStr = "{0:D2}:{1}" -f $length.Hours, $lengthStr }

        return $response.information.category.meta.filename, $timeStr, $lengthStr
    } catch {
        Write-Host "Error while fetching VLC status: $_"
        return $null, $null, $null
    }
}

# Twitch IRC Configuration
$server = "irc.chat.twitch.tv"
$port = 6697
$nick = [System.Environment]::GetEnvironmentVariable('TWITCH_USERNAME')
$password = [System.Environment]::GetEnvironmentVariable('TWITCH_OAUTH_TOKEN')
$channel = [System.Environment]::GetEnvironmentVariable('TWITCH_CHANNEL')

# Create TCP Client and connect to Twitch IRC
$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($server, $port)
$sslStream = New-Object System.Net.Security.SslStream $client.GetStream()
$sslStream.AuthenticateAsClient($server)
$writer = New-Object System.IO.StreamWriter $sslStream
$reader = New-Object System.IO.StreamReader $sslStream

# Send authentication and join channel
$writer.WriteLine("PASS oauth:$password")
$writer.WriteLine("NICK $nick")
$writer.WriteLine("JOIN #$channel")
$writer.Flush()

# Initialize last command time
$lastCommandTime = Get-Date -Date "01/01/1970 00:00:00"

# Main loop to read chat and respond to commands
while($true) {
    $readData = $reader.ReadLine()
    Write-Host "Received: $readData"  # Debug statement

    if ($readData -match "PING :tmi.twitch.tv") {
        $writer.WriteLine("PONG :tmi.twitch.tv")
        $writer.Flush()
    }

    foreach ($cmd in $commands) {
        if ($readData -match ":.*?$cmd") {
            $currentTime = Get-Date
            $timeSinceLastCommand = $currentTime - $lastCommandTime

            if ($timeSinceLastCommand.TotalSeconds -ge 30) {
                $currentSong, $time, $length = Get-CurrentlyPlayingVLC
                if ($null -ne $currentSong -and $null -ne $time -and $null -ne $length) {
                    $response = "PRIVMSG #$channel :Now Playing: $currentSong $time/$length"
                    $writer.WriteLine($response)
                    $writer.Flush()

                    # Update last command time
                    $lastCommandTime = $currentTime
                } else {
                    Write-Host "Couldn't fetch current song or time from VLC"  # Debug statement
                }

            } else {
                Write-Host "Cooldown in effect. Skipping command."  # Debug statement
            }
            break
        }
    }
}
