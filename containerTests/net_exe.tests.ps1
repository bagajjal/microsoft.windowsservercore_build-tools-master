Describe "Verify container contain files work properly" {

    $files =@(
        @{file = "$env:windir\system32\net.exe"}
        @{file = "$env:windir\syswow64\net.exe"}
    )

    it "should contain functional <file>" -TestCases $files {
        param(
            [parameter(Mandatory)]
            [string]$file
            
        )
    
        $result = &$file user | Where-Object {-not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1

        $result | should match '^(User accounts for)'
    }
}