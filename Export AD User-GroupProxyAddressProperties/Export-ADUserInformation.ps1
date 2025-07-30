# Variable set up - edit here
$exportrootfolder = "<<LOCAL PATH>>"
$datestamp = get-date -f yyyy-MM-dd_HHmmss
$exportCSVFile = "$exportrootfolder\ADUsers-List-$datestamp.csv"
$PreferredDC = "<<DOMAINCONTROLLER NAME>>"
###################################
# End of edit zone

# Export list of all users with properties of interest
$Users = Get-ADUser -Filter "enabled -eq '$true'" -Server $PreferredDC -Properties * | select UserPrincipalName, samAccountName, DisplayName, DistinguishedName, surname, mail, givenname, title, department, streetaddress, state, country, office, city, postalcode, officephone, mobilephone, company, ProxyAddresses
$Users | select UserPrincipalName, samAccountName, DisplayName, DistinguishedName, surname, mail, givenname, title, department, streetaddress, state, country, office, city, postalcode, officephone, mobilephone, company | Export-Csv -NoTypeInformation  -path $exportCSVFile 
$Count = $Users.Count
# Confirm outcome
Write-Host "Wrote $Count enabled user records to $exportCSVFile" -ForegroundColor Yellow

# Export group memberships to subfolder, per user
If ($Count -gt 0 ) {
    $ADUserCount = 0
    $outcome = New-Item -Path "$exportrootfolder\ADUsers-$datestamp-ProxyAddressesPerUser" -ItemType Directory
    $ProxyAddressUsers = $Users | select samAccountName, ProxyAddresses
    ForEach ($ProxyAddressUser in $ProxyAddressUsers) {
        $ADUserCount++
        $exportProxyAddressFile = "$exportrootfolder\ADUsers-$datestamp-ProxyAddressesPerUser\$($ProxyAddressUser.samAccountName)_ProxyAddresses.csv“
        ($ProxyAddressUser.ProxyAddresses) | Out-File $exportProxyAddressFile
        Write-Host " ($ADUserCount/$Count) Wrote proxy addresses for $($ProxyAddressUser.samAccountName) user to CSV $exportProxyAddressFile" -ForegroundColor White
    }
    $ADUserCount = 0

    $outcome = New-Item -Path "$exportrootfolder\ADUsers-$datestamp-GroupMembershipsPerUser" -ItemType Directory
    ForEach ($ADUser in $Users) {
        $ADUserCount++
        $exportGroupMembershipFile = "$exportrootfolder\ADUsers-$datestamp-GroupMembershipsPerUser\$($ADUser.samAccountName)_UserGroups.csv“

        Get-ADPrincipalGroupMembership -Identity $($ADUser.DistinguishedName) -Server $PreferredDC | select name, groupcategory, groupscope | 
        export-CSV $exportGroupMembershipFile  -NoTypeInformation
        Write-Host " ($ADUserCount/$Count) Wrote group memberships for $($ADUser.DisplayName) to CSV $exportGroupMembershipFile" -ForegroundColor White
    }
}
# Check and report the outcome
$MeasureExport = Import-CSV $exportCSVFile | Measure-Object
$MeasureProxyAddressFiles = Get-ChildItem -Path "$exportrootfolder\ADUsers-$datestamp-ProxyAddressesPerUser" | Measure-Object
$MeasureGroupfiles = Get-ChildItem -Path "$exportrootfolder\ADUsers-$datestamp-GroupMembershipsPerUser" | Measure-Object

Write-Host "Export completed:" -ForegroundColor Yellow
Write-Host " - Exported $($MeasureExport.Count) enabled AD Users to $exportCSVFile"
Write-Host " - Exported $($MeasureProxyAddressFiles.Count) sets of ProxyAddresses to files in $exportrootfolder\ADUsers-$datestamp-ProxyAddressesPerUser"
Write-Host " - Exported $($MeasureGroupFiles.Count) sets of Group Memberships files in $exportrootfolder\ADUsers-$datestamp-GroupMembershipsPerUser"
