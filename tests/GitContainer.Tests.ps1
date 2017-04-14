function Write-TestResults
{
    param(
        [Parameter(Mandatory)]
        [string]
        $resultPath
    )

    [xml]$result= (Get-Content -raw $resultPath)
    # switch between methods, SelectNode is not available on dotnet core
    if ( "System.Xml.XmlDocumentXPathExtensions" -as [Type] ) {
        $testCases = [System.Xml.XmlDocumentXPathExtensions]::SelectNodes($result."test-results",'.//test-case')
    }
    else {
        $testCases = $result.SelectNodes('.//test-case')
    }
    $tests=@{}
    foreach ( $testCase in $testCases )
    {
        $name = $testCase.description
        $describe = $testCase.name.Replace($name, "")
        if(-not $tests.Contains($describe))
        {
            $tests += @{$describe=@()}
        }
        $tests.$describe += $testCase
    }
    foreach($describe in $tests.keys)
    {
        Context $describe {
            foreach($testCase in $tests.$describe)
            {
                it $testCase.Description {
                    switch($testCase.Result)
                    {
                        "Success"{
                            $true | should be $true
                        }
                        "Failure"{
                            Write-Error -Message ($testCase.failure.message + [Environment]::newline + $testCase.failure."stack-trace") -ErrorAction Stop
                        }
                        default {
                            $testCase.Result | should beexactly "knowresult"
                        }
                    }
                }
            }
        }
    }        
}
$repoName = &"$psscriptroot\..\reponame.ps1"
Describe "Tests in Container $repoName pass"{
    BeforeAll{
        $resultFileName = 'results.xml'
        $resolvedTestDrive = (Resolve-Path "Testdrive:\").providerPath
        $resolvedXmlPath = Join-Path $resolvedTestDrive -ChildPath $resultFileName
        $containerTestDrive = 'C:\test'        
        $containerXmlPath = Join-Path $containerTestDrive -ChildPath $resultFileName
    }
    BeforeEach
    {
        Remove-Item $resolvedXmlPath -ErrorAction SilentlyContinue
    }
    
    it "Running tests should produce xml" {
        docker run --rm -v "${resolvedTestDrive}:$containerTestDrive" $repoName Invoke-Pester .\containerFiles\Tests -OutputFile $containerXmlPath -OutputFormat NUnitXml
        $resolvedXmlPath | should exist
    }
    if(test-Path $resolvedXmlPath)
    {
        Write-TestResults -resultPath $resolvedXmlPath
    }

    it "Running tests should produce xml in container with 4GB RAM" {
        docker run --rm -v "${resolvedTestDrive}:$containerTestDrive" -m 3968m $repoName Invoke-Pester .\containerFiles\Tests -OutputFile $containerXmlPath -OutputFormat NUnitXml
        $resolvedXmlPath | should exist
    }
    if(test-Path $resolvedXmlPath)
    {
        Write-TestResults -resultPath $resolvedXmlPath
    }
}
