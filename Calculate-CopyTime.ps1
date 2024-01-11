$OutputList = @()
Get-ChildItem *.log | ForEach-Object {
    #Write-Host "Processing Log $_"
    $StartTimeRaw = Get-Content $_ | Select-String "Started :"
    $EndTimeRaw = Get-Content $_ | Select-String "Ended :"
    $SourcePath = Get-Content $_ | Select-String "Source :"

    if (($StartTimeRaw) -AND $EndTimeRaw)
    {
        [DateTime]$StartTimeDT= $StartTimeRaw.ToString().Replace('  Started : ',"").Trim()
        [DateTime]$EndTimeDT = $EndTimeRaw.ToString().Replace('  Ended : ',"").Trim()
        [String]$SourcePathStr = $SourcePath.ToString().Replace('   Source : ',"").Trim()

        $CopyTime = New-TimeSpan $StartTimeDT -End $EndTimeDT
        
        $CopyResult = New-Object -Type PSObject
		$CopyResult | Add-Member -Name 'SourcePath' -Type NoteProperty -Value $SourcePathStr
		$CopyResult | Add-Member -Name 'CopyTime' -Type NoteProperty -Value $CopyTime.ToString("dd\.hh\:mm\:ss")
        $OutputList += $CopyResult
        Write-Host "Copy from '$SourcePathStr' took is $($CopyTime.ToString("dd' days 'hh' hours 'mm' minutes 'ss' seconds'"))"
    }
}

$OutputList | Export-Csv -Path CopyTimes.csv -NoTypeInformation
$OutputList | ogv
