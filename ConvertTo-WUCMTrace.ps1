<#
Disclaimer

This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance 
of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for 
any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the 
use of or inability to use the sample scripts or documentation, even if Microsoft has been advised 
of the possibility of such damages
#>

<#
.SYNOPSIS
   Creates a CMTrace compatible Logfile from the Windows 10 / Server 2016/19 Windows Updates ETL-Files
.DESCRIPTION
Creates a CMTrace compatible Logfile from the Windows 10 / Server 2016/19 Windows Updates ETL-Files.
Afterwards, you can merge this file with other MECM related files. Might be useful for further troubleshooting
.EXAMPLE
ConvertTo-WuCMTrace
Start CMTrace and open the created Logfile
.NOTES
Author:  Microsoft (ChNieb@Microsoft.com)
Version: 1.0
Date:    11/06/2017
#>
function ConvertTo-WUCMTrace
{
    [CmdletBinding()]
    param
    (
        [string]
        $LogPath = "$env:userprofile\desktop\WindowsUpdateCmtrace.log"
    )

    Get-WindowsUpdateLog -LogPath $env:TEMP\wulog.log 
    $content = Get-Content -Path $env:TEMP\wulog.log 
    Remove-Item -Path $env:TEMP\wulog.log -Force

    $count = $content.Count
    $counter = 1
    $output = New-Object -TypeName System.Collections.ArrayList
    foreach($line in $Content)
    {
        Write-Progress -Activity "Convert WindowsUpdate.log" -Status "Converting Log Entries" -PercentComplete (($counter++)*100 / $count) -CurrentOperation "Line $counter from $count"
        $split = $line.split(" ")
        $date = [Datetime]::Parse(($split[0..1] -join " "))
        $processID = $split[2]
        $component = $split[5]
        $message = [string]::Empty
        if($line -match "(?<Message>(?<=   ).+)")
        {
            $message = $Matches.Message.Trim()
        }

        $logTime = Get-Date -Date $date -Format "HH:mm:ss.fff"
        $logDate = Get-Date -Date $date -Format "MM-dd-yyyy"
        $LogTimePlusBias = "{0}-000" -f $logTime
        $null= $output.Add(('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="1" thread="{4}" file="WindowsUpdateCmtrace.log">' -f $message, $LogTimePlusBias, $logDate, $component, $processID))
    }     
         $output | Out-File  -FilePath $LogPath -Encoding utf8 -Force

}

ConvertTo-WUCMTrace
