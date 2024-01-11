function MountAndCopy {
	param (
		$storageaccountname,
		$destsharename,
		$sourcepath,
		$storageaccountrg,
		$subscriptionname
	)
	try {
		$AzContext = Get-AzContext -ListAvailable | ?{$_.Subscription.Name -eq "$subscriptionname"}
		$user = "localhost\$storageaccountname"
		$key = (Get-AzStorageAccountKey -ResourceGroupName $storageaccountrg -Name $storageaccountname -DefaultProfile $AzContext)[0].Value
		[securestring]$seckey = ConvertTo-SecureString $key -AsPlainText -Force
		[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($user, $seckey)
	}
	catch {
		Write-Host "Error obtaining key for storage acount $storageaccountname in RG $storageaccountrg in sub $subscriptionname!"
		Exit
	}

	$timeout = New-TimeSpan -Seconds 30
	$endTime = (Get-Date).Add($timeout)
	try {
		do { #Try mouting
			$driveletter = FindFreeDriveLetter
			$result = New-PSDrive -Name $driveletter -PSProvider FileSystem -Root "\\$storageaccountname.file.core.windows.net\$destsharename" -Credential $credObject -Persist -ErrorAction SilentlyContinue
		} until ($result -or ((Get-Date) -gt $endTime))
		
		Write-Host "Using drive letter $($result.Name)`: for $($result.DisplayRoot)"
		#ROBOCOPY COMMAND
		$sourceserver = $sourcepath.Substring(2,$sourcepath.SubString(2).IndexOf("\"))
		Write-Host "Starting Robocopy Source: $sourcepath Dest: $driveletter`: pointing to \\$storageaccountname.file.core.windows.net\$destsharename"
		robocopy "$sourcepath" "$driveletter`:" /MT:20 /R:0 /W:0 /B /MIR /IT /COPY:DATSO /DCOPY:DAT /NP /NFL /NDL /XD "System Volume Information" /UNILOG:"$sourceserver-$destsharename.log" #/IORATE:30m

		Remove-PSDrive -Name $driveletter -force
		remove-smbmapping -LocalPath $driveletter`: -force -erroraction 'silentlycontinue'
		net use \\$storageaccountname.file.core.windows.net\$destsharename /delete 2>$null
	}
	catch {
		Write-Host "COPY FAILED: Source: $sourcepath Dest: $driveletter`: pointing to \\$storageaccountname.file.core.windows.net\$destsharename"
		Exit
	}
}

function FindFreeDriveLetter(){
  $reserved="ABCZ".ToCharArray()
  $drvlist=(Get-PSDrive -PSProvider filesystem).Name
  Foreach ($drvletter in [char[]](65..90) | Sort-Object {Get-Random}) {
    If ($drvletter -notin $reserved -and $drvlist -notcontains $drvletter) {
      return $drvletter
    }
  }
  throw "no free, unreserved drive letters"
}

function LogIt($LogMessage)
{
	$LogFileName = "RunnerLog.log"
	$DateT = Get-Date -format G
	Write-Host "$DateT CopyFiles - $LogMessage"
	Add-content $LogFileName -value "$DateT CopyFiles - $LogMessage"
}

$Commands = @(
'MountAndCopy -storageaccountname "<<DEST STORAGE ACCOUNT NAME>>" -destsharename "<<DEST SHARE NAME>>" -sourcepath "<<SOURCE FILE SHARE PATH>>" -storageaccountrg "<<STORAGEACCOUNT RESOURCEGROUP NAME>>" -subscriptionname "<<STORAGE ACCOUNT SUBSCRIPTION NAME>>"',
'MountAndCopy -storageaccountname "storageaccount01" -destsharename "fileshare1" -sourcepath "\\OLDSERVER\fileshare1" -storageaccountrg "rg-prod-storageaccounts-01" -subscriptionname "Company1-Production"',
'MountAndCopy -storageaccountname "storageaccount02" -destsharename "fileshare2" -sourcepath "\\OLDSERVER\fileshare2" -storageaccountrg "rg-prod-storageaccounts-02" -subscriptionname "Company1-Production"',
'MountAndCopy -storageaccountname "storageaccount03" -destsharename "fileshare3" -sourcepath "\\OLDSERVER\fileshare3" -storageaccountrg "rg-prod-storageaccounts-03" -subscriptionname "Company1-Production"'
)

$Commands = $Commands | Sort-Object {Get-Random}
$MountAndCopy = ${function:MountAndCopy}.ToString() # Get the function's definition *as a string*
$FindFreeDriveLetter = ${function:FindFreeDriveLetter}.ToString() # Get the function's definition *as a string*
$LogIt = ${function:LogIt}.ToString() # Get the function's definition *as a string*

$Count = 0
$Commands | ForEach-Object -Parallel {
	${function:MountAndCopy} = $using:MountAndCopy #Import function
	${function:FindFreeDriveLetter} = $using:FindFreeDriveLetter #Import function
	${function:LogIt} = $using:LogIt #Import function
	LogIt "Copy Starting: '$_'"
	Invoke-Expression -Command $_
	LogIt "Copy Complete: '$_'"
	$Count = $using:Count #Import function
	$Count++
} -ThrottleLimit 12