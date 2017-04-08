$repoName = &"$psscriptroot\reponame.ps1"
Describe "Verify containers contain expected commands" {
    $repos = @(
        @{
            repo = $repoName
            command = 'git.exe'
        }
        @{
            repo = $repoName
            command = 'cmake.exe'
        }
        @{
            repo = $repoName
            command = 'nuget.exe'
        }
    )

    it "<repo> should contain <command>" -TestCases $repos {
        param(
            [parameter(Mandatory)]
            [string]$repo,
            [parameter(Mandatory)]
            [string]$command
            
        )
        $stderr = 'testdrive:\stderr.txt'
        $stdout = 'testdrive:\stdout.txt'
        $powershellArguments = '-command &{1}if(get-command -name {0} -erroraction silentlycontinue){1}write-output "Exists"{2}else{1}write-output "NotFound"{2}{2}' -f $command,'{','}'
        Write-Verbose -Message "Running powershell in container with: $powershellArguments" -Verbose
        start-process -Wait -filepath docker `
            -argumentlist @(
                'run'
                '--rm'
                "${repo}:latest"
                'powershell'
                $powershellArguments
            ) `
            -RedirectStandardError $stderr `
            -RedirectStandardOutput $stdout `
            -NoNewWindow
        $stderr | should Exist
        $stdout | should Exist
        Get-Content $stderr | should benullorempty
        Get-Content $stdout | should beexactly 'Exists'
    }
}