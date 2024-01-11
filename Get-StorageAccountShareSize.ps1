$Subs = Get-AzSubscription

$OutputList = @()
try {
	Foreach ($Sub in $Subs) {
		Set-AzContext -Subscription $Sub.id *>$null
        #Get storageaccount names
        $storageAccount = Get-AzStorageAccount

        #Now iterate over the storageaccounts
        foreach ($storage in $storageAccount) { 
            if($storage.PrimaryEndpoints.File -ne $null){
                $shares = Get-AzRmStorageShare -ResourceGroupName $storage.ResourceGroupName -StorageAccountName $storage.StorageAccountName
                foreach ($share in $shares) {
                    $shareName = $share.Name
                    $accountName = $share.StorageAccountName
                    $storageaccountrg = $storage.ResourceGroupName
                    $subname = $sub.name

                    Write-Host "Working on share $shareName and on storage account $accountName in the resource group $storageaccountrg on sub $subname"
                    
                    $AzContext = Get-AzContext -ListAvailable | ?{$_.Subscription.Name -eq $subname}
                    $key = (Get-AzStorageAccountKey -ResourceGroupName $storageaccountrg -Name $accountName -DefaultProfile $AzContext)[0].Value

                    $ctx = New-AzStorageContext -StorageAccountName $accountName -StorageAccountKey $key
                    $shareob = Get-AzStorageShare -Name $shareName -Context $ctx
                    $client = $shareob.ShareClient
                    # We now have access to Azure Storage SDK and we can call any method available in the SDK.
                    # Get statistics of the share
                    $stats = $client.GetStatistics()
                    $shareUsageInBytes = $stats.Value.ShareUsageInBytes
                    [int]$ShareUsageInGB = $shareUsageInBytes / 1024 /1024 /1024
                    [int]$ShareQuotaInGB = $share.QuotaGiB
                    [int]$ShareFreeInGB = $ShareQuotaInGB - $ShareUsageInGB

                    $ShareData = New-Object -Type PSObject
                    $ShareData | Add-Member -Name 'SubscriptionName' -Type NoteProperty -Value $subname
                    $ShareData | Add-Member -Name 'ResourceGroupName' -Type NoteProperty -Value $storageaccountrg
                    $ShareData | Add-Member -Name 'StorageAccountName' -Type NoteProperty -Value $accountName
                    $ShareData | Add-Member -Name 'ShareName' -Type NoteProperty -Value $shareName
                    $ShareData | Add-Member -Name 'ShareQuotaInGB' -Type NoteProperty -Value $ShareQuotaInGB
                    $ShareData | Add-Member -Name 'ShareUsageInGB' -Type NoteProperty -Value $ShareUsageInGB
                    $ShareData | Add-Member -Name 'ShareFreeInGB' -Type NoteProperty -Value $ShareFreeInGB
                    $OutputList += $ShareData

                }
            }
        }
	}
}
catch 
{
    Write-Error -Message $_.Exception
    throw $_.Exception
}

$OutputList | Export-Csv -Path ShareSizes.csv -NoTypeInformation
$OutputList | ogv




