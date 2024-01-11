$Paths = @(
"\\OLDSERVER\fileshare1",
"\\OLDSERVER\fileshare2",
"\\OLDSERVER\fileshare3"
)

ForEach ($Path in $Paths) {
	$server = $Path.Substring(2,$Path.SubString(2).IndexOf("\"))
	$share = $Path.Substring($Path.LastIndexOf("\")+1)
	
	$s = New-PsSession -ComputerName $server
	[String]$cmd = "Get-SmbShareAccess '$share'"
	[ScriptBlock]$sb = [ScriptBlock]::Create($cmd) 
	$Output += Invoke-Command -Session $s -ScriptBlock $sb
}
$Output | Export-Csv -Path .\SharePermissions.csv -NoTypeInformation