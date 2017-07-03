Describe "Verify container contain expected commands" {
    $commands = @(
        @{
            command = 'git.exe'
        }
        @{
            command = 'cmake.exe'
        }
        @{
            command = 'nuget.exe'
        }
    )

    it "should contain <command>" -TestCases $commands {
        param(
            [parameter(Mandatory)]
            [string]$command
            
        )

        get-command -name $command -erroraction silentlycontinue | should not benullorempty
    }
}