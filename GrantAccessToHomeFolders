#Created by Daniel Sarfati
#This code grants all of the users access to their home folder. For use only on a single AD domain environment. Grants user "Modify" Access, to change alter line 15.

$folderlist=Get-ChildItem -Directory

function getUserID($userID)
{
	$userID = get-ADUser $userID
	return $ENV:Userdomain + "\" + $($userid.samaccountname)
}

function setACL($foldername)
{
	$NewFolderACL = (Get-Item $foldername).GetAccessControl('Access')
	$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule((getUserID($foldername.basename)), 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
	$NewFolderACL.SetAccessRule($Ar)
	Set-Acl $foldername.fullname -AclObject $NewFolderACL
}

forEach ($folder in $folderList)
{ setacl $folder }
