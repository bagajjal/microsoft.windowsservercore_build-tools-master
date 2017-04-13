$repoName = &"$psscriptroot\..\reponame.ps1"
Describe "Tests in Container $repoName pass"{
    BeforeAll{
        $resultFileName = 'results.xml'
        $resolvedTestDrive = (Resolve-Path "Testdrive:\").providerPath
        $resolvedXmlPath = Join-Path $resolvedTestDrive -ChildPath $resultFileName
        $containerTestDrive = 'C:\test'        
        $containerXmlPath = Join-Path $containerTestDrive -ChildPath $resultFileName
    }
    it "Running tests should produce xml" {
        docker run --rm -v "${resolvedTestDrive}:$containerTestDrive" $repoName Invoke-Pester .\containerTests -OutputFile $containerXmlPath -OutputFormat NUnitXml
        $resolvedXmlPath | should exist
    }
    [xml]$result= (Get-Content -raw $resolvedXmlPath)
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
