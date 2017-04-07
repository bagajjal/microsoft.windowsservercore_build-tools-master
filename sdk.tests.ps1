        Describe "win10sdk" {
            $repos = @(
                @{repo = 'travisez13/microsoft.windowsservercore.build-tools'}
            )

            it "<repo> should contain win10sdk" -TestCases $repos {
                param(
                    [parameter(Mandatory)]
                    [string]$repo
                )

                #todo replace with an actual test for the sdk
                start-process -Wait -filepath docker -argumentlist @('run', "${repo}:latest", 'git', 'version') -PassThru  -RedirectStandardError Testdrive:\stderr.txt -RedirectStandardOutput testdrive:\stdout.txt 
                Get-Content testdrive:\stderr.txt | should benullorempty
                Get-Content testdrive:\stdout.txt | should belike 'git version *.windows.*'
            }
        }