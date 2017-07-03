Install-ChocolateyPackage -PackageName vcbuildtools -ArgumentList @(
    '-ia'
    '"/InstallSelectableItems VisualCppBuildTools_ATLMFC_SDK;VisualCppBuildTools_NETFX_SDK"'
)
Set-SdkEnv
Remove-Win10SdkPackageCache
