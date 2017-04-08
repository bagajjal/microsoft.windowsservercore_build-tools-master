$repoName = &"$psscriptroot\reponame.ps1"
Describe "Verify containers contain expected files" {
    $repos = @(
        @{
            repo = $repoName
            file = '${env:ProgramFiles(x86)}\Windows Kits\10\Include\activation.h'
        }
    )

    it "<repo> should contain <file>" -TestCases $repos {
        param(
            [parameter(Mandatory)]
            [string]$repo,
            [parameter(Mandatory)]
            [string]$file
            
        )
        $stderr = 'testdrive:\stderr.txt'
        $stdout = 'testdrive:\stdout.txt'
        $powershellArguments = '-command &{1}if(Get-ChildItem -Recurse -Path \"{0}\" -erroraction silentlycontinue){1}write-output "Exists"{2}else{1}write-output "NotFound"{2}{2}' -f $file.Replace('\','/'),'{','}'
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