Function Test-SpeedSamba {
    param (
        $source,
        $target
    )
    $startedAt = Get-Date -Format "dd.MM.yyyy H:m:ss"
    $item = get-item $source
    $time=Measure-Command -Expression {Copy-Item -literalpath $source $target} 
    $TransferRate = ($item.length/1024/1024) / $time.TotalSeconds
    $finishedAt = Get-Date -Format "dd.MM.yyyy H:m:ss"
    $result = New-Object -TypeName psobject -Property @{
        StartedAt        = $startedAt
        FinishedAt      = $finishedAt
        Source           = $item.fullname
        Target           = $target
        TimeTaken        = [math]::Round($time.TotalSeconds,2)
        TransferRateMBs  = [math]::Round($TransferRate,2)
    }
    return $result
}

Function Test-SpeedSambaWithCount {
    param (
        $source,
        $target,
        $count
    )
    $i = 0;
    $result = @()
    do {
        $result += Test-SpeedSamba -source $source -target $target
        $i++
    } while ($i -lt $count)
    return $result
}


Function Test-SpeedWeb{
    param (
        $target = 'https://ftp.sunet.se/mirror/parrotsec.org/parrot/misc/10MB.bin'
    )
    # The test file has to be a 10MB file for the math to work. If you want to change sizes, modify the math to match
    $startedAt = Get-Date -Format "dd.MM.yyyy H:m:ss"
    $TestFile  = $target
    $TempFile  = Join-Path -Path $env:TEMP -ChildPath 'testfile.tmp'
    $WebClient = New-Object Net.WebClient
    $TimeTaken = Measure-Command { $WebClient.DownloadFile($TestFile,$TempFile) } | Select-Object -ExpandProperty TotalSeconds
    $SpeedMbpsCalc = (10 / $TimeTaken) * 8
    $SpeedMbps = "{0:N2} Mbit/sec" -f ($SpeedMbpsCalc)
    $finishedAt = Get-Date -Format "dd.MM.yyyy H:m:ss"

    $result = [PSCustomObject]@{
        StartedAt   = $startedAt
        FinishedAt  = $finishedAt
        Target      = $target
        TimeTaken   = $TimeTaken
        SpeedMbps   = $SpeedMbps
    }
    return $result
}

Function Test-SpeedWebWithCount {
    param (
        $target,
        $count
    )
    $i = 0
    $result = @()
    do{
        $result += Test-SpeedWeb -target $target
        $i++
    } while( $i -lt $count)
    return $result
}


Function Test-SpeedIperf3 {
    param (
        $target = "iperf.cageops.com"
    )
    ###
    # Author: Dave Long <dlong@cagedata.com>
    # Gets an bandwidth test using iPerf3. Sum is the download speed of computer.
    # Article Source: https://davejlong.com/testing-network-bandwidth-from-powershell/
    ###

    $iPerfDownload = "https://iperf.fr/download/windows/iperf-3.1.3-win64.zip"
    $DownloadLocation = Join-Path $env:TEMP "iperf.zip"
    $iPerfPath = Join-Path $env:TEMP "iperf"

    if (!(Test-Path $iPerfPath)) {
    Invoke-WebRequest -Uri $iPerfDownload -OutFile $DownloadLocation
    Expand-Archive -Path $DownloadLocation -DestinationPath $iPerfPath
    }
    Set-Location (Join-Path $iPerfPath "iperf-3.1.3-win64")

    $Download = & .\iperf3.exe --client $target --port 5210 --parallel 10 --reverse
    if (($Download | Select-Object -Last 1) -eq "iperf Done.") {
    Write-Host "Download Speed"
    $Download | Select-Object -Last 4 | Select-Object -First 2 | Write-Host
    } else {
    Write-Host "iPerf failed to get download speed."
    }
    $Upload = & .\iperf3.exe --client $target --port 5210 --parallel 10
    if (($Upload | Select-Object -Last 1) -eq "iperf Done.") {
    Write-Host "Upload Speed"
    $Upload | Select-Object -Last 4 | Select-Object -First 2 | Write-Host
    } else {
    Write-Host "iPerf failed to get upload speed."
    }
}





#Requires -Version 3
function Test-SpeedTest
{
    <#
        .SYNOPSIS
        Report your internet Download and Upload speed.
  
        .DESCRIPTION
        SpeedTester leverages speedtest.net hosting servers. SpeedTester will identify the closest hosting servers
        to you and pick the one with the lowest latency to perform a test download and upload. It will then report
        the average Download and Upload in Mbps.
             
        Start-SpeedTest does not accept any parameters at this stage.
 
        .EXAMPLE
        Start-SpeedTest
        Runs SpeedTester with default Download and Upload parameters
 
        .EXAMPLE
        Start-SpeedTest -DownloadMB 10 -Upload 10
        Runs SpeedTester with a download size of 10 MB and an Upload size of 10 MB.
        Valid range is 1 - 30 for both Download and Upload represented in MB only.
             
        .EXAMPLE
        Start-SpeedTest -DownloadMB 20 -Verbose
        Runs SpeedTester with a download size of 20 MB with Verbose logging
             
        .INPUTS
        None
  
        .NOTES
        Author: Mark Ukotic
        Website: http://blog.ukotic.net
        Twitter: @originaluko
        GitHub: https://github.com/originaluko/
 
        .LINK
        https://github.com/originaluko/SpeedTester
 
    #>

    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateRange(1,30)]
        [Double]$UploadMB = "7.5",
        [ValidateRange(1,30)]
        [Double]$DownloadMB = "7.5"
    )

    # Server distance helper function
    function Get-ServerInfo {
    
        param(
            [Parameter(Mandatory=$true)]
            $servers 
        )
          
        foreach($server in $servers) 
        { 
            $radius = 6371
            [float]$dlat = ([float]$orilat - [float]$server.lat) * 3.14 / 180
            [float]$dlon = ([float]$orilon - [float]$server.lon) * 3.14 / 180
            [float]$a = [math]::Sin([float]$dlat/2) * [math]::Sin([float]$dlat/2) + [math]::Cos([float]$orilat * 3.14 / 180 ) * [math]::Cos([float]$server.lat * 3.14 / 180 ) * [math]::Sin([float]$dlon/2) * [math]::Sin([float]$dlon/2)
            [float]$c = 2 * [math]::Atan2([math]::Sqrt([float]$a ), [math]::Sqrt(1 - [float]$a))
            [float]$d = [float]$radius * [float]$c

            New-Object PSObject -Property @{
                Distance = $d
                Country = $server.country
                Sponsor = $server.sponsor
                Url = $server.url
                Host = $server.host
            }
        }
    }

    # Avg Ping response helper function
    function Get-AvgPing {  
        param(
            [Parameter(Mandatory=$true)]
            $servers 
        )

        foreach ($server in $servers) { 
     
            try {
                Write-Verbose "Testing ping to $server"
                $test = (Test-Connection -ComputerName $server -Count 4 -ErrorAction Stop | measure-Object -Property ResponseTime -Average).average 
                $response = ($test -as [decimal] ) 
            }   
            catch [System.Net.NetworkInformation.PingException] {
                Write-Warning "$server is offline."
            } 
            catch {
                Write-Warning "Ping test failed for $server"
            }   
            finally {
                New-Object PSObject -Property @{
                    'Destination' = $server
                    'Avg' = $response
                }    
                Write-Verbose "$response ms average ping to $server"
            }
        }
    }
    
    # Download Test helper function
    function Get-DataWCAsync{
        param(
            [Parameter(Mandatory=$true)]
            $Url, 
            [switch]$IncludeStats,
            [ValidateRange(1,30)]
            [Double]$DownloadMB = "7.5"
        )
        $global:download = ($DownloadMB * 1mb)
        $global:wc = New-Object Net.WebClient
        $wc.UseDefaultCredentials = $false
        $wc.Headers.Add("Content-Type","application/x-www-form-urlencoded") 
        $wc.Headers.Add("Accept: text/html, application/xhtml+xml, */*")
        $wc.Headers.Add("User-Agent", "Mozilla/4.0 (compatible; MSIE 6.0;Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322)")
        $wc.Headers.Add("Cache-Control", "no-cache")
        $wc.Headers.Add("Referer", "http://www.speedtest.net")
        $start = Get-Date 
        $null = Register-ObjectEvent -InputObject $wc -EventName DownloadProgressChanged -MessageData @{start=$start;includeStats=$includestats} -SourceIdentifier WebClient.DownloadProgressChanged -Action { 
            filter Get-FileSize {
                "{0:N2} {1}" -f $(
                    if ($_ -lt 1kb) { $_, 'Bytes' }
                    elseif ($_ -lt 1mb) { ($_/1kb), 'KB' }
                    elseif ($_ -lt 1gb) { ($_/1mb), 'MB' }
                    elseif ($_ -lt 1tb) { ($_/1gb), 'GB' }
                    elseif ($_ -lt 1pb) { ($_/1tb), 'TB' }
                    else { ($_/1pb), 'PB' }
                )
            }
            $time = ((Get-Date) - $event.MessageData.start)
            $averagespeed = ($eventargs.BytesReceived * 8 / 1MB) / $time.TotalSeconds
            $elapsed = $Time.ToString('hh\:mm\:ss')
            $remainingseconds = ($eventargs.TotalBytesToReceive - $eventargs.BytesReceived) * 8 / 1MB / $averagespeed
            $receivedsize = $eventargs.BytesReceived | Get-FileSize
            $received = $eventargs.BytesReceived
            $totalSize = $download | Get-FileSize 
            $percent = $eventargs.BytesReceived / $download * 100
            $percent = [Math]::Round($percent)  
            
            If ($received -ge $download) {
                $wc.CancelAsync()
            }
                          
            Write-Progress -Activity (" $url {0:N2} Mbps" -f $averagespeed) -Status ("{0} of {1} ({2}% in {3})" -f $receivedSize,$totalsize,$percent,$elapsed) -SecondsRemaining $remainingseconds -PercentComplete $percent
            if ($percent -eq 100){
                Write-Progress -Activity (" $url {0:N2} Mbps" -f $averagespeed) -Status 'Done' -Completed
                
                if ($event.MessageData.includeStats.IsPresent){
                    $global:down = [Math]::Round($averageSpeed, 2) 
                } 
            }
        }    
        $null = Register-ObjectEvent -InputObject $wc -EventName DownloadDataCompleted -SourceIdentifier WebClient.DownloadDataCompleted -Action { 
            Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
            Unregister-Event -SourceIdentifier WebClient.DownloadDataCompleted
        }
    
        try  {  
            Write-Verbose "Performing download from $url"
            $wc.DownloadDataAsync($url)  
        }  
        catch [System.Net.WebException]  {  
            Write-Warning "Download of $url failed"  
        }   
        finally  {    
            while ($wc.IsBusy) {}
            $wc.Dispose() 
        }  
    }
    
    # Upload Test helper function
    function Push-DataWCAsync{
        param(
            [Parameter(Mandatory=$true)]
            $url, 
            $byteArray,
            [switch]$includeStats
        )
        $wc = New-Object Net.WebClient
        $wc.UseDefaultCredentials = $false
        $wc.Headers.Add("Content-Type","application/x-www-form-urlencoded") 
        $wc.Headers.Add("Accept: text/html, application/xhtml+xml, */*")
        $wc.Headers.Add("User-Agent", "Mozilla/4.0 (compatible; MSIE 6.0;Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322)")
        $wc.Headers.Add("Cache-Control", "no-cache")
        $wc.Headers.Add("Referer", "http://www.speedtest.net")
        $start = Get-Date 
        $null = Register-ObjectEvent -InputObject $wc -EventName UploadProgressChanged -MessageData @{start=$start;includeStats=$includeStats} -SourceIdentifier WebClient.UploadProgressChanged -Action { 
            filter Get-FileSize {
                "{0:N2} {1}" -f $(
                    if ($_ -lt 1kb) { $_, 'Bytes' }
                    elseif ($_ -lt 1mb) { ($_/1kb), 'KB' }
                    elseif ($_ -lt 1gb) { ($_/1mb), 'MB' }
                    elseif ($_ -lt 1tb) { ($_/1gb), 'GB' }
                    elseif ($_ -lt 1pb) { ($_/1tb), 'TB' }
                    else { ($_/1pb), 'PB' }
                )
            }
            
            $Time = ((Get-Date) - $event.MessageData.start)
            $averageSpeed = ($eventargs.BytesSent * 8 / 1MB) / $Time.TotalSeconds
            $elapsed = $Time.ToString('hh\:mm\:ss')
            $remainingSeconds = ($eventargs.TotalBytesToSend - $eventargs.BytesSent) * 8 / 1MB / $averageSpeed
            $receivedSize = $eventargs.BytesSent | Get-FileSize
            $totalSize = $eventargs.TotalBytesToSend | Get-FileSize  
            $percent = $eventargs.BytesSent / $eventargs.TotalBytesToSend * 100
            $percent = [Math]::Round($percent)   
                       
            Write-Progress -Activity (" $url {0:N2} Mbps" -f $averageSpeed) -Status ("{0} of {1} ({2}% in {3})" -f $receivedSize,$totalSize,$percent,$elapsed) -SecondsRemaining $remainingSeconds -PercentComplete $percent
            if ($eventargs.ProgressPercentage -eq 100){
                Write-Progress -Activity (" $url {0:N2} Mbps" -f $averageSpeed) -Status 'Done' -Completed
                
                if ($event.MessageData.includeStats.IsPresent){
                    $global:upload = [Math]::Round($averageSpeed, 2) 
                }
            }
        }    
        # $null = Register-ObjectEvent -InputObject $wc -EventName UploadDataCompleted -SourceIdentifier WebClient.UploadDataCompleted -Action {
        # Unregister-Event -SourceIdentifier WebClient.UploadProgressChanged -Force
        # Unregister-Event -SourceIdentifier WebClient.UploadDataCompleted -Force
        # }
        
        try  {  
            Write-Verbose "Performing upload to $url"
            $wc.UploadDataAsync($url,'POST',$byteArray) 
        }  
        catch [System.Net.WebException]  {  
            Write-Warning "Upload of $url failed"  
        }   
        finally  { 
            while ($wc.IsBusy) {}   
            $wc.Dispose()  
            Remove-Job * -Force
        }
    }
    
    Write-Output 'Retrieving configuration...'

    $uri = 'http://beta.speedtest.net/speedtest-config.php'
    try {
        [xml]$config = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-Error "Could not download configuration from $uri"
        Break
    }

    $ip = $config.settings.client.ip
    $isp = $config.settings.client.isp
    Write-Output "Testing from $isp ($ip)"

    $orilat = $config.settings.client.lat
    $orilon = $config.settings.client.lon

    Write-Output 'Retrieving server list...'

    $uri = 'http://www.speedtest.net/speedtest-servers.php'
    try {
        [xml]$hosts = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-Error "Could not download server list from $uri"
        Break
    }

    Write-Output 'Selecting best server...'

    $servers = $hosts.settings.servers.server
        
    # Sort the distance of each server
    $closestserver = Get-ServerInfo -Servers $servers | Sort-Object -Property distance
    
    $servers = $closestserver[0],$closestserver[1],$closestserver[2]
    $serverurlspilt = ($servers).host -split ':8080'
    $servers = $serverurlspilt[0],$serverurlspilt[2],$serverurlspilt[4] 
    
    # Get avg ping response
    $bestserver = Get-AvgPing -servers $servers

    # Getting lazy and just want lowest latency server asap
    $index = 0
    $minvalue = [decimal]::MaxValue
    $bestserver.avg | ForEach-Object { if ($minvalue -gt $_) {$minvalue = $_; $minindex = $index}; $index++ }
     
    $location = $closestserver[$index].sponsor
    $distance = $closestserver[$index].distance
    Write-Output "Hosted by $location [$distance km] ($minvalue ms)"

    $serverurlspilt = ($closestserver[$index]).url -split 'upload'
    $url = $serverurlspilt[0] + "random4000x4000.jpg"
    
    Write-Output 'Testing download speed...'
    Get-DataWCAsync -Url $url -DownloadMB $downloadmb -IncludeStats 
      
    if ($down -eq $null) {
    Write-Output "Oh no, we couldn't calculate download average"}
    else {
        Write-Output "Download: $down Mbps"
    }
 
    # Creating a random byte array to avoid bad download data messing with the upload
    $bytearray = New-Object Byte[] ($uploadmb * 1mb)
    (New-Object Random).NextBytes($bytearray)
    
    $url = ($closestserver[$index]).url
    Write-Output 'Testing upload speed...'
    Push-DataWCAsync -url $url -byteArray $bytearray -includeStats        

    if ($upload -eq $null) {
    Write-Output "Oh no, we couldn't calculate upload average"}
    else {
        Write-Output "Upload: $upload Mbps"
    }
    Write-Output 'Tests Completed' 
}