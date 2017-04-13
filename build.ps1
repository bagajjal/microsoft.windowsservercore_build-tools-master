param(
    [string[]]
    $Tags = 'latest',
    [switch]
    $NoCache
)
$repoName = &"$psscriptroot\reponame.ps1"
$tagParams = @()
foreach($tag in $tags)
{
    $tag = $tag.ToLowerInvariant()
    $tagParams += '-t'
    $tagParams += "${repoName}:$tag"
}
if($NoCache)
{
    $tagParams += '--no-cache'
}
$startTime = Get-date
docker build $tagParams $PSScriptRoot
$endTime = Get-date
[timespan] $duration = $endTime - $startTime
Write-Verbose "Build took $($duration.TotalMinutes) minutes" -Verbose
Invoke-Pester "$PSScriptRoot\tests"