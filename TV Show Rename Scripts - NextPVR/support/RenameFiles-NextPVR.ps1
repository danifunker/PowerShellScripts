<#
Title: RenameFiles.ps1
Description: Changes nextPVR TS and associated files for Plex - Also checks TVDB for more information and reads the headers
Comments: None
Author: danifunker (plex)
Original Date: February 19 2015
Dependancies: get-ld.ps1 - this file is renamed to .psm1 and wrapped into a function (http://www.codeproject.com/Tips/102192/Levenshtein-Distance-in-Windows-PowerShell), DVRMSToolbox, .NET
PSSQLLite - https://psqlite.codeplex.com/ (and it's dependencies)
Version: 1.3
#>

[cmdletBinding()]
param(
	[Parameter(Mandatory=$True,Position=1)]
	[int]$oid
	)

$NextPVRDBLocation="C:\users\public\NPVR\npvr.db3"
$NPVRInstallDir="C:\Program Files (x86)\NPVR"
#Register for an apikey at http://thetvdb.com/wiki/index.php?title=Programmers_API

#Install Module PSSqlLite from https://psqlite.codeplex.com/
import-module "C:\support\PSSQLite-master\PSSQLite\PSSQLite.psm1"
#import-module "C:\support\psqlite\start-SQLite.psm1"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.web")
#[void][System.Reflection.Assembly]::LoadFile("\\danihtpc-pc\C$\Program Files (x86)\DVRMSToolbox\babgVant.DvrmsToolbox.Shared.dll")
#import-module $PSScriptRoot\TVDBFunctions.psm1
#import-module $PSScriptRoot\OtherSharedFunctions.psm1
#import-module $PSScriptRoot\get-ld.psm1
import-module C:\support\TVRenameScripts\TVDBFunctions.psm1
import-module C:\support\TVRenameScripts\OtherSharedFunctions.psm1
import-module C:\support\TVRenameScripts\get-ld.psm1

$runType=1

$minFileAgeSeconds=""
$MinToRound=5

$QueryForRecording="Select * From SCHEDULED_RECORDING Where oid=$oid"

$recordingResults=Invoke-SQLiteQuery -DataSource $NextPVRDBLocation -Query $QueryforRecording

function gatherShowDetails()
{
	$xmlDataTranslate=[xml]$recordingresults.event_details
	$ActualRecordDate=(get-date $recordingResults.start_time).ToLocalTime()
	$recordDateRounded=RoundTime -timeToRound $ActualRecordDate -NumOfMin $MinToRound
	$returnOBJ=new-object PSObject
	Add-Member -InputObject $returnOBJ -MemberType NoteProperty -Name ChannelName -Value  ($recordingResults.channel_name)
	Add-Member -InputObject $returnOBJ -MemberType NoteProperty -Name OrigFileName -Value  (gci $recordingResults.filename).Name
	Add-Member -InputObject $returnOBJ -MemberType NoteProperty -Name OrigFileNameNoExt -Value $returnObj.OrigFileName.ToString().SubString(0,$returnObj.OrigFilename.ToString().LastIndexOf("."))
	add-member -inputobject $returnobj -MemberType NoteProperty -Name ShowTitle -Value $xmlDataTranslate.Event.title
	#Check if this is a re-run
	if ($xmlDataTranslate.Event.OriginalAirDate)
		{add-member -inputobject $returnobj -MemberType NoteProperty -Name OrigAirDate -Value $xmlDataTranslate.Event.OriginalAirDate}
	#if not a rerun, set the OrigAirDate to the date of the recording
	else
		{add-member -inputobject $returnobj -MemberType NoteProperty -Name OrigAirDate -Value (get-date $recordDateRounded -format yyyy-MM-dd)}
	add-member -inputobject $returnobj -MemberType NoteProperty -Name EpisodeName -Value $xmlDataTranslate.Event.SubTitle
	add-member -inputobject $returnobj -MemberType NoteProperty -Name RecordDate -value $recordDateRounded
	add-member -inputobject $returnobj -MemberType NoteProperty -Name FullPath -value $recordingResults.filename
	add-member -inputobject $returnobj -MemberType NoteProperty -Name FolderName -value (gci $recordingResults.filename).DirectoryName	
	add-member -inputobject $returnObj -MemberType Noteproperty -Name EPGDescription -value $xmlDataTranslate.Event.Description
	add-member -inputobject $returnObj -MemberType Noteproperty -Name FirstRun -value $xmlDataTranslate.Event.FirstRun
	add-member -inputobject $returnObj -MemberType Noteproperty -Name SeasonEPG -value $xmlDataTranslate.Event.Season
	add-member -inputobject $returnObj -MemberType Noteproperty -Name EpisodeEPG -value $xmlDataTranslate.Event.Episode
	add-member -inputobject $returnObj -MemberType Noteproperty -Name FileExtension -value $recordingResults.filename.ToString().SubString($recordingResults.filename.ToString().LastIndexOf("."))
	
	forEach ($genre in $xmlDataTranslate.Event.Genres)
	{
		if ($genre -eq "Movie")
		{add-member -inputobject $returnObj -MemberType Noteproperty -Name IsMovie -value $true}
		else 
		{add-member -inputobject $returnObj -MemberType Noteproperty -Name IsMovie -value $false
		break}
	}
	$xmlDataTranslate=$null
	return $returnObj
}
$file=gatherShowDetails

#The recorded file wasn't a movie, according to NextPVR
if ($file.IsMovie -eq $False)
{
	#Uncomment next line to generate code to move folders
	#$newFileName=(ScrapeInvalidFileNameChars($($file.ShowTitle.Value)))+"\"+(ScrapeInvalidFileNameChars($($file.ShowTitle.Value)))
	$newFileName=(ScrapeInvalidFileNameChars($($file.ShowTitle)))
	#Check TVDB First for a match
	if ($file.OrigAirDate -ne "0001-01-01T00:00:00Z" -or $file.OrigAirDate -eq "")
	{
		$TVDBResults=checkTVDB -ShowDetails $file
		if ($TVDBResults.Matched -ne $false)
		#Match found, get all the data from TVDB, and structure the filename like that
		{
			$returnSeriesName=ScrapeInvalidFileNameChars($TVDBResults.SeriesName)
			$returnEpisodeName=ScrapeInvalidFileNameChars($TVDBResults.EpisodeName)
			$newFileName="$returnSeriesName - $($TVDBResults.EPCode) - $returnEpisodeName"
			#Uncomment the next line to generate code to move folders, but comment the line above
			#$newFileName="$returnSeriesName\Season $($TVDBResults.SeasonNumber)\$returnSeriesName - $($TVDBResults.EPCode) - $returnEpisodeName"
		}
	}
	#If there is no match on TVDB (either because we didn't check, or it didn't match a result)
	if (($file.EpisodeName.Length -gt 0) -and ($TVDBResults.Matched -eq $false))
	{
		$newFileName="$newFileName - "+(ScrapeInvalidFileNameChars($($file.EpisodeName)))
	}
	if (($file.EpisodeName.Length -lt 1) )
	{
		
		#This is a daily program
	}
	#Append Recording Date to FileName to avoid colllosions (this is not read by Plex)
	$newFileName="$newFileName - "+(get-date($($file.RecordDate)) -Format yyyy-MM-dd)+" - " + (get-date ($($file.RecordDate)) -Format HH-mm)+"_$($file.ChannelName)"
	$returnNew=new-object PSObject
	add-member -inputObject $returnNew -memberType NoteProperty -Name OrigFullPath -value $file.FullPath
	add-member -inputobject $returnNew -membertype NoteProperty -Name OrigFileName -value $file.OrigFileName
	add-member -inputObject $returnNew -membertype NoteProperty -Name NewFileName -value $newFileName
	if ($TVDBResults.Matched -eq $true)
	{
		add-member -inputObject $returnNew -memberType NoteProperty -Name FolderPath -value (join-Path (get-item (get-item $file.FolderName).Parent.fullname).fullname (ScrapeInvalidFileNameChars($TVDBResults.SeriesName)))
		if (!(test-path $ReturnNew.FolderPath))
			{
			#Creates the folder if it doesn't exist already if the folder has to be renamed
			New-Item -Path $ReturnNew.FolderPath -ItemType Directory -Force | Out-Null
			}
	}
	else
	{
		add-member -inputObject $returnNew -memberType NoteProperty -Name FolderPath -value $file.FolderName
	}
	add-member -inputObject $returnNew -memberType NoteProperty -Name OrigFolderPath -value $file.FolderName
	add-member -inputObject $returnNew -memberType NoteProperty -Name OrigFileNameNoExt -value $file.OrigFileNameNoExt
	add-member -inputObject $returnNew -memberType NoteProperty -Name NewFullPathName -value (Join-path ($returnNew.FolderPath) ($returnNew.NewFileName + $file.FileExtension))
	$newFileName=$null

	#Find the Files to Rename and rename them
	$filesToRename=dir -file -path $returnNew.OrigFolderPath | Where-Object {$_.BaseName.StartsWith($returnNew.OrigFileNameNoExt)}
	# Make sure comskip isn't running, if it is we need to wait for it to finish before proceeding with the rest of the script
	
	forEach ($associatedFile in $filesToRename)
	{
		move-item -path $associatedFile.FullName -destination (Join-Path $returnNew.FolderPath $associatedFile.Name.Replace($returnNew.OrigFileNameNoExt,$returnNew.NewFileName))
	}
		
		#Now update the database
		#$PathNameCleaned=$returnNew.NewFullPathName.Replace("'","''")
		#$updatePathQuery="UPDATE SCHEDULED_RECORDING set filename='$PathNameCleaned' WHERE oid='$OID'"
		
		#Execute Update
		start-process -filePath "$NPVRInstallDir\NScriptHelper.exe" -ArgumentList "-rename ""$($file.FullPath)"" ""$($returnNew.NewFullPathName)""" -PassThru
		#Don't update the database manually, this kills the recording, using NScriptHelper.exe instead
		#Invoke-SQLiteQuery -DataSource $NextPVRDBLocation -Query $updatePathQuery
		return $returnNew.NewFullPath
}
