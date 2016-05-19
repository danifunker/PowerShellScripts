[CmdletBinding()]
param(
	[Parameter (Mandatory)]
	[ValidateScript({Test-Path $_ -Pathtype Container})][String]$FolderName
)

[reflection.assembly]::LoadFile("C:\windows\ExiftoolWrapper.dll")
$obj=New-Object BBCSharp.ExifToolWrapper("C:\windows\exiftool-k.exe")

$obj.start()



Function Remove-InvalidFolderNameChars {
  param(
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [String]$Name
  )

  $invalidChars = [System.IO.Path]::GetInvalidPathChars() -join ''
  $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
  return ($Name -replace $re)
}

Function GetNewFileName($oldFileName){

	$output=$obj.SendCommand($oldFileName.FullName)
	$newObj=$output.Split("`n")
	$returnObj=New-Object PSObject
	forEach ($prop in $newObj)
	{
		if ($prop)
		{
		$CleanProp=$prop.Replace("`n","")
		$CleanProp=$prop.Replace("`r","")
		$tempProp=$prop.Split("`t")
		Add-Member -MemberType NoteProperty -InputObject $returnObj -Name $tempProp[0].toString() -Value $tempProp[1].toString() -force
		} 
	}
	$newFileName= $oldFileName.DirectoryName + "\" + (get-date $returnObj.'Date/Time Original' -Format "yyyy-MM-dd HH.mm.ss") + "." + $returnObj.'File Type'.ToLower()
	return $newFileName

}

Function GetNewFileName-NoEXIF($oldFileName){

	$newFileName= $oldFileName.DirectoryName + "\" + (get-date $oldFileName.LastWriteTime -Format "yyyy-MM-dd HH.mm.ss") + $oldFileName.Extension
	return $newFileName

}

$allFiles= (gci $folderName -Recurse) | where-object {$_.extension.toLower() -eq ".jpg" -or $_.extension.toLower() -eq ".jpeg" -or $_.extension.toLower() -eq ".mts" -or $_.extension.toLower() -eq ".m2ts" -or $_.extension.toLower() -eq ".mov"}


$filestoChange=$allfiles | Where-Object {$_.name -notlike "*-*"}

forEach ($improperlyNamedFiles in $filestoChange)

{

$newFileName=GetNewFileName $improperlyNamedFiles
$newFileName2=$newFileName -replace '\[','`[' -replace '\]','`]'

move-item -Path $improperlyNamedFiles.FullName -Destination (Remove-InvalidFolderNameChars  $newFileName).ToString()
}

#noExif

#$noExifFiles=$allfiles | where-object {$_.extension.toLower() -eq ".mov" -or $_.extension -eq ".avi"} | where-object {$_.name -nolike "*-*"}

#forEach ($file in $noExifFiles)

#{
#$newFileName=GetNewFileName-NoEXIF $file
#Move-Item -Path $file.fullname -Destination $newFileName
#}

$obj.stop()