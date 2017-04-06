# Script is compatible with Windows 2008 R2
# Sets the SSL Certificate binding if the certificate installed is different from the one in the certificate store

$hostname="www.myexternalname.com"
$bindingIP="0.0.0.0:443"


$newThumbprint= dir cert:\localmachine\my | where-object {$_.subject -like "CN=$hostname"} | Select-Object -ExpandProperty Thumbprint
$sslCertBindings=netsh http show sslcert ipport=$bindingIP
$bindingExists=$sslCertBindings | where-object {$_ -like "*${newthumbprint}*"}

if (!($bindingExists))
{
	# Update the site now!
	$AppIDString=$sslCertBindings | Where-Object {$_ -like "*Application ID*"}
	$AppID=$appIDString.Substring($AppIDString.IndexOf("{"))
	netsh http del sslcert ipport=$bindingIP
	netsh http add sslcert ipport=$bindingIP certhash=$newThumbprint appid=($appid.Substring(0,($AppID.Length-1)))
}
