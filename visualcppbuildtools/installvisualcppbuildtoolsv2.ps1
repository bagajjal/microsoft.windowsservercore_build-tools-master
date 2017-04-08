Install-ChocolateyPackage -PackageName vcbuildtools -ArgumentList @(
    '-ia'
    '"/InstallSelectableItems VisualCppBuildTools_ATLMFC_SDK;VisualCppBuildTools_NETFX_SDK;Win10SDK_VisibleV1"'
)
Set-SdkEnv
Remove-Win10SdkPackageCache
