function Remove-Win10SdkPackageCache
{
    Remove-Folder "$env:ProgramData\Package Cache"
}