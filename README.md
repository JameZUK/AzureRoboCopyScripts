#     AzureRoboCopyScripts

A bunch of useful PowerShell scripts to ease data migrations to Azure Files

To use these scripts, first you need to be logged in via Connect-AzAccount. I'm hoping the filenames and code will be self explanitory but here is a brief overview of each of the scripts function:

Calculate-CopyTime.ps1 - This script will read all robocopy log files in the directory and calculate the data copy times for each one. It will output the data in GridView and CSV File.
