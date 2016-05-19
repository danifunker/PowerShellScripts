function ScrapeInvalidFileNameChars
{
Param(
    [Parameter(
        Mandatory=$true,
        Position=0, 
        ValueFromPipelineByPropertyName=$true
    )]
    [String]$Name,
    [switch]$IncludeSpace
)
if ($IncludeSpace) {
    [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '_')
	}
else {
    [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape(-join [System.IO.Path]::GetInvalidFileNameChars())), '_')
	}
}

function RoundTime($timeToRound,$NumOfMin)
{
	#This function rounds the time to the nearst $NumOfMin minute
	$datePart = $timeToRound.Date
	$minutePart = $timeToRound.Minute
	$hourPart = $timeToRound.Hour
	$rounding = ([system.Math]::Round($minutePart / $numOfMin))*$numOfMin
	return ($datePart.addminutes(($hourPart*60)+$rounding))
}
