#TVDB Setup
New-Variable -Name APIKey -value 'MYKEY' -Scope Global
$mirrors= irm "Http://thetvdb.com/api/$apikey/mirrors.xml"
$mirrorpath = $mirrors.Mirrors.Mirror | ? { $_.typemask -band 1} | get-random | select -expandproperty mirrorpath
$languages = irm "$Mirrorpath/api/$apikey/languages.xml"
$english = $languages.languages.language | ? name -eq English
$currentTime = irm "$mirrorpath/api/Updates.php?type=none"

function checkTVDB($ShowDetails)
{
	$SeriesEncoded=[System.Web.HttpUtility]::UrlEncode("$($showdetails.ShowTitle)")
	$SeriesName= irm "$mirrorpath/api/GetSeries.php?seriesname=$seriesEncoded"
	#The above line returns a list of series names, let's check to see which one matches before we say "OK" to it
	$potentialSeriesID=@()
	forEach ($hit in $SeriesName.data.series)
	{
		$returnobj=new-object PSObject
		add-member -inputObject $returnObj -MemberType NoteProperty -Name SeriesName -Value $hit.SeriesName
		add-member -inputObject $returnObj -MemberType NoteProperty -Name ID -Value $hit.seriesid
		add-member -inputObject $returnObj -MemberType NoteProperty -Name Network -Value $hit.Network
		add-member -inputObject $returnObj -MemberType NoteProperty -Name Language -Value $hit.Language
		add-member -inputObject $returnObj -MemberType NoteProperty -Name Description -Value $hit.Overview
		$potentialSeriesID+=$returnObj
		$returnObj=$null
	}
	forEach ($potentialHit in $potentialSeriesID)
	{
	$airDate=($showdetails.OrigAirDate).ToString().substring(0,10)
	$episodeResult=irm "$mirrorpath/api/GetEpisodeByAirDate.php?apikey=$apikey&seriesid=$($potentialhit.ID)&airdate=$airDate"
	if (((get-ld -first $episodeResult.data.Episode.EpisodeName -second $ShowDetails.EpisodeName -lt 5) -or ($episodeResult.Data.Episode.EpisodeName -eq $ShowDetails.EpisodeName) -or ($ShowDetails.EpisodeName -lt 1)) -and ($episodeResult.Data.Episode -ne ""))
	#We have found a match!
		{
		$SeasonNmbr="{0:D2}" -f [int]($episodeResult.data.Episode.SeasonNumber)
		$EpisodeNmbr="{0:D2}" -f [int]($episodeResult.data.Episode.EpisodeNumber)
		$FullEpisodeTxt="`S$SeasonNmbr`E$EpisodeNmbr"
		$TVDBResults=New-object PSObject
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name Matched -Value $true
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EPcode -Value $FullEpisodeTxt
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeasonNumber -Value $SeasonNmbr
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EpisodeNumber -Value $EpisodeNmbr
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EpisodeName -Value $episodeResult.data.Episode.EpisodeName
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name OverView -Value $episodeResult.data.Episode.Overview
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeriesName -Value $potentialHit.SeriesName
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeriesNameLookup -Value $ShowDetails.ShowTitle
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name OrigAirDate -Value $ShowDetails.OrigAirDate
		if ($TVDBResults -ne $null)
			{ return $TVDBResults
			break }
		}
	}
	if ($TVDBResults -eq $null)
	{
		$TVDBResults=New-object PSObject
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name Matched -Value $false
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EPcode -Value "NA"
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeasonNumber -Value "NA"
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EpisodeNumber -Value "NA"
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name EpisodeName -Value "NA"
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name OverView -Value "NA"
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeriesName -Value $potentialHit.SeriesName
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name SeriesNameLookup -Value $ShowDetails.ShowTitle		
		Add-Member -inputObject $TVDBResults -MemberType NoteProperty -Name OrigAirDate -Value $ShowDetails.OrigAirDate		
		return $TVDBResults
	}
}
