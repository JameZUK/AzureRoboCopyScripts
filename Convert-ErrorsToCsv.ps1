$OutputList = @()
Get-ChildItem *.log | ForEach-Object {
    Write-Host "Processing Log $_"
    $ErrorLines = Get-Content $_ | Select-String ' ERROR \d\d' -Context 0,1
    if ($ErrorLines)
    {
        $ErrorDetail = $ErrorLines[0].ToString().Split([Environment]::NewLine)[0].Trim().Replace('> ','')
        $ErrorDescription = $ErrorLines[0].ToString().Split([Environment]::NewLine)[1].Trim()

        [String]$ErrorDT = $ErrorDetail.Split('ERROR ')[0]
        [String]$ErrorCode = $ErrorDetail.Split('ERROR ')[1].Split(')')[0] + ')'
        
        $TempArray = $ErrorDetail.Split('ERROR ')[1].Split(')')[1].Trim().Split()
        [String]$ErrorOperation = $TempArray[0] + " " + $TempArray[1]
        [String]$ErrorPath = $ErrorDetail.Split($ErrorOperation)[1].Trim()
     
        $ErrorResult = New-Object -Type PSObject
		$ErrorResult | Add-Member -Name 'ErrorPath' -Type NoteProperty -Value $ErrorPath
        $ErrorResult | Add-Member -Name 'ErrorCode' -Type NoteProperty -Value $ErrorCode
        $ErrorResult | Add-Member -Name 'ErrorDescription' -Type NoteProperty -Value $ErrorDescription
		$ErrorResult | Add-Member -Name 'ErrorDT' -Type NoteProperty -Value $ErrorDT
        $OutputList += $ErrorResult
    }
}

$OutputList | Export-Csv -Path CopyErrors.csv -NoTypeInformation
$OutputList | ogv