#     AzureRoboCopyScripts

A bunch of useful PowerShell scripts to ease data migrations to Azure Files

To use these scripts, first you need to be logged in via Connect-AzAccount. I'm hoping the filenames and code will be self explanitory but here is a brief overview of each of the scripts function:

**Copy-Data.ps1** - This is the main script in this repo. The script will run robocopy and start a datacopyy from the source path to the destination storage account. Due to the way azure files works, the azure files share will be mounted with the storage account secret (As per MS guidelines) which will be automatically collected from the storage account by the script. The script supports multiple concurrent copies (Add a new command for each share in the $Commands array - examples are in the file)  and will start them in seperate threads for good performance. You can change the concurrenty by changing the -ThrottleLimit setting. 
**Copy-Data-WaitForTime.ps1** - This script is the sanme as the above Copy-Data.ps1 script but also has the ability to start itself as a specified time every day. It uses a simple countdown time so you can see how logn before the script runs, in addition this script will launch Beyond Compare after each copy has completed - Quite useful to see how well the copy went.
**Calculate-CopyTime.ps1** - This script will read all robocopy log files in the directory and calculate the data copy times for each one. It will output the data in GridView and CSV File.
**Convert-ErrorsToCsv.ps1** - This script will read all robocopy log files in the directory and output all error files into a GridView and CSV File. Really useful to summerise huge log files or make a report for a customer / project.
**Get-SMBSharePermissions** - This script will retrieve file share permissions and output them into a CSV file.
**Get-StorageAccountShareSize** - This script will iterate through all subscriptions and then all storage accounts and retrieve the file share sizes from each
