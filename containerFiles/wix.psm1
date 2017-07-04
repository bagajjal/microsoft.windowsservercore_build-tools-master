function Install-WixZip
{
    param($zipPath)

    $targetRoot = "${env:ProgramFiles(x86)}\WiX Toolset xcopy"
    $binPath = Join-Path -Path $targetRoot -ChildPath 'bin'
    if(-not (Test-Path $targetRoot))
    {
        $null = New-Item -Path $targetRoot -ItemType Directory
    }
    Expand-Archive -Path $zipPath -DestinationPath $binPath
    $docExpandPath = Join-Path -Path $binPath -ChildPath 'doc'
    $sdkExpandPath = Join-Path -Path $binPath -ChildPath 'sdk'
    $docTargetPath = Join-Path -Path $targetRoot -ChildPath 'doc'
    $sdkTargetPath = Join-Path -Path $targetRoot -ChildPath 'sdk'
    Move-Item -Path $docExpandPath -Destination $docTargetPath
    Move-Item -Path $sdkExpandPath -Destination $sdkTargetPath
}