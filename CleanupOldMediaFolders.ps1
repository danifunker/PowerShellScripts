<#
Title: CleanupOldMediaFolders.ps1
Description: Cleanup Folders without Media files
Comments: None
Author: Daniel Sarfati
Original Date: April 16 2014
Modified Date: April 16 2014
Version: 1.0
#>
[CmdletBinding()]
param(
	[Parameter (Mandatory)]
	[ValidateScript({Test-Path $_ -Pathtype Container})][String]$FolderName
)
$ScriptName = $MyInvocation.MyCommand.Name

$MediaFiles=@(".mp3",".mov",".mp4",".m4v",".mkv",".vob",".vod",".mpg",".qt",".avi",".iso",".3gp",".divx",".xvid",".wtv",".dvr-ms",".img",".bin",".m2ts",".ts",".flv")

$filelist = Get-ChildItem $foldername -recurse
$folderlist = $filelist | where-object PSIsContainer
$filesonlylist = $filelist | where PSIsContainer -eq $false

foreach ($fullname in $folderlist.fullname)
	{
		$filesincurrentFolder=$filelist | where-object {$_.directory -like $fullname}
		$foldersincurrentFolder=$folderlist | where-object {$_.parent.fullname -like $fullname}
		$goodfilesInFolder=$filesincurrentFolder | where-object extension -in $Mediafiles
		if ($filesincurrentFolder.count -lt 1 -and $foldersincurrentFolder.count -lt 1) {remove-item -LiteralPath $fullname -recurse -force}
		else 
		{
			if ($goodfilesInFolder.count -lt 1 -and $foldersincurrentFolder.count -lt 1) {remove-item -LiteralPath $fullname -recurse -force}
			#else {write-host "The folder $fullname will be deleted"}
		}
	}