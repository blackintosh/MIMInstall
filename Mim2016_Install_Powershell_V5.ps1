#***************************************************************************************
# This scrit is Composed/Found/stolen and modify by Nils Cronstedt And Jonas Novesten
# And its free to use and modify 
# This script downloads SharePoint Server 2016 RTM
# Only run this script on Windows Server 2012 R2
# Run this script as a local server Administrator
# Run PowerShell as Administrator
# Don't forget to: Set-ExecutionPolicy RemoteSigned, in case you have not done already
#
# Create c:\temp for logs etc
# 
# 
#
# This is fore the SQL Install  Needs to tested and Developed more
# .\setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION=install /FEATURES=SQL /INSTANCENAME=MSSQLSERVER /SQLSVCACCOUNT="contoso\sharepoint" /SQLSVCPASSWORD="Pass@word1"   /AGTSVCSTARTUPTYPE=Automatic /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /SQLSYSADMINACCOUNTS="contoso\Administrator"
#****************************************************************************************

# Acounts that will be used or created

$MIMMA = "MIMMA"
$MIMSync = "MIMSync"
$MIMService = "MIMService"
$MIMSP = "MIMSP"
$MIMAdmin = "MIMAdmin"
$dbManagedAccount ="Sharepoint"

# Password for users and for service accounts

$PasswdMIMMA = "Pass@word1"
$PasswdMIMSync = "Pass@word1"
$PasswdMIMService = "Pass@word1"
$PasswdMIMSP = "Pass@word1"
$PasswdMIMAdmin = "Pass@word1"
$passwddbManagedAccount ="Pass@word1"

# Portal Settings

$SPUrl = "http://portal.mim.nu"
$SPWeb = "http://portal.mim.nu:80"
$SPdbManagedAccount = "mim\sharepoint"
$SPPortalName = "MIM Portal"
$SPApplicationPool = "MIMAPPPool"
$SPAuthenticationMethod = "Kerberos" 
$SPPort = "80"
$OwnerAlias = "mim\MIMAdmin"
$SecondaryOwnerAlias = "mim\administrator"
$CompatibilityLevel = "15"
$New_SPAlternateURL = "http://localhost"
$Ie_Zone = "intranet"

# OU this is for the function to create the OU Path for users and groups in ad
# TO be dev some way to simplify handel of Variables
# OU=User,OU=Lab,DC=mim,DC=nu

$Dn_Root = "DC=mim,DC=nu"
$Dn_Company = "lab"
$Dn_Company_Path = "OU=Lab,DC=mim,DC=nu"
$OU ="User"
$path = "OU=User,OU=Lab,DC=mim,DC=nu" 

# Setspn serviceclass/host:portnumber servicename
# To be dev I function that check how many SPN there is and add those

$setspn1 = "HTTP/portal.mim.nu mim\MIMSP"
$setspn2 = "HTTP/mim mim\MIMSP"
$setspn3 = "MIMService/portal.mim.nu mim\MIMService"
$setspn4 = "MIMSync/mim mim\MIMSync"

# windows server ISO path
$source = "F:\sources\SxS" 

# Directory path where SharePoint 2016 Pre-requisites files are kept
$PreRequsInstallerPath = "d:\"

$SharePoint2016RTMPath = "C:\temp\SharePoint2016\"
# $PreRequsInstallerPath # Folder Variables have the same value

# Directory path where SharePoint 2016 RTM files are kept

$PreRequsFilesPath = "C:\temp\SharePoint2016\"

# E:\Synchronization Service

$SynchronizationServiceExe = "E:\Synchronization Service\Synchronization Service.msi"
$syncLofFile = "C:\temp\synclog.log"

# Service and Portal path

$PortalPath = "e:\Service and Portal\Service and Portal.msi"
$PortalLogPath = "c:\temp\service_Portal.log"

# Install Service and Portal parameters
$MAIL_SERVER = Hostname
$SQLSERVER_SERVER = "CM1"
$SERVICE_ACCOUNT_NAME = $MIMService
$SERVICE_ACCOUNT_PASSWORD = $PasswdMIMService
$SERVICE_ACCOUNT_DOMAIN = $env:USERDOMAIN
$SERVICE_ACCOUNT_EMAIL = "Administrator@" + $SERVICE_ACCOUNT_DOMAIN + ".com"
$RUNNING_USER_EMAIL = "Administrator@" + $SERVICE_ACCOUNT_DOMAIN + ".com"
$SYNCHRONIZATION_SERVER_ACCOUNT = $MIMSync
$SYNCHRONIZATION_SERVER = Hostname
$SERVICEADDRESS = Hostname
$REGISTRATION_ACCOUNT = $env:USERDOMAIN + "\" + $MIMMA
$REGISTRATION_ACCOUNT_PASSWORD = $PasswdMIMMA
$REGISTRATION_SERVERNAME= Hostname
$REGISTRATION_PORTAL_URL = "http://localhost:8087"
$RESET_ACCOUNT = $env:USERDOMAIN + "\" + $MIMMA
$RESET_ACCOUNT_PASSWORD = $PasswdMIMMA
$RESET_SERVERNAME = Hostname
$SHAREPOINT_URL = $SPWeb
$MIMPAM_ACCOUNT_DOMAIN = $env:USERDOMAIN
$LOGFILENAME = $PortalLogPath

# Dont edit script below
#-------------------------------------------------------------------------------------

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'Have you run Prerequest installer'
$msg   = 'Y / N'

$text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

Read-Host "Press ENTER"  #Easy Pause to be removed


# Import Required Modules

Import-Module BitsTransfer

# Specify download url's for SharePoint Server 2016 RTM prerequisites

$DownloadUrls = (
            "http://download.microsoft.com/download/4/B/1/4B1E9B0E-A4F3-4715-B417-31C82302A70A/ENU/x64/sqlncli.msi", # Microsoft SQL Server 2012 SP1 Native Client
	    "https://download.microsoft.com/download/5/7/2/57249A3A-19D6-4901-ACCE-80924ABEB267/ENU/x64/msodbcsql.msi", #Microsoft ODBC Driver 11 for SQL Server
            "http://download.microsoft.com/download/E/0/0/E0060D8F-2354-4871-9596-DC78538799CC/Synchronization.msi", # Microsoft Sync Framework Runtime v1.0 SP1 (x64)
            "http://download.microsoft.com//download/0/1/D/01D06854-CA0C-46F1-ADBA-EBF86010DCC6/rtm/MicrosoftIdentityExtensions-64.msi", # Microsoft Identity Extensions
            "http://download.microsoft.com/download/A/6/7/A678AB47-496B-4907-B3D4-0A2D280A13C0/WindowsServerAppFabricSetup_x64.exe", # Windows Server AppFabric 1.1
            "http://download.microsoft.com/download/F/1/0/F1093AF6-E797-4CA8-A9F6-FC50024B385C/AppFabric-KB3092423-x64-ENU.exe", # Cumulative Update 7 for Microsoft AppFabric 1.1 for Windows Server
            "http://download.microsoft.com/download/3/C/F/3CF781F5-7D29-4035-9265-C34FF2369FA2/setup_msipc_x64.exe", # Microsoft Information Protection and Control Client
            "http://download.microsoft.com/download/1/C/A/1CAA41C7-88B9-42D6-9E11-3C655656DAB1/WcfDataServices.exe", # Microsoft WCF Data Services 5.6
            "http://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe", # Visual C++ Redistributable Package for Visual Studio 2015,
            "http://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe",# Another visual C++ Redistributable Package for Visual Studio 2013/2012,
            "https://download.microsoft.com/download/C/3/A/C3A5200B-D33C-47E9-9D70-2F7C65DAAD94/NDP46-KB3045557-x86-x64-AllOS-ENU.exe" # .NET framework 4.6
                )

function DownLoadPreRequisites()
{
    Write-Host ""
    Write-Host "=============================================================================================="
    Write-Host "      Downloading SharePoint Server 2016 RTM Prerequisites Please wait..."
    Write-Host "=============================================================================================="

    $ReturnCode = 0
    foreach ($DownLoadUrl in $DownloadUrls)
    {
        ## Get the file name based on the portion of the URL after the last slash
        $FileName = $DownLoadUrl.Split('/')[-1]
        Try
        {
            ## Check if destination file already exists
            If (!(Test-Path "$SharePoint2016RTMPath\$FileName"))
            {
                ## Begin download
                Start-BitsTransfer -Source $DownLoadUrl -Destination $SharePoint2016RTMPath\$fileName -DisplayName "Downloading `'$FileName`' to $SharePoint2016RTMPath" -Priority High -Description "From $DownLoadUrl..." -ErrorVariable err
                If ($err) {Throw ""}
            }
            Else
            {
                Write-Host " - File $FileName already exists, skipping..."
            }
        }
        Catch
        {
            $ReturnCode = -1
            Write-Warning " - An error occurred downloading `'$FileName`'"
            Write-Error $_
            break
        }
    }
    Write-Host "Done downloading Prerequisites required for SharePoint Server 2016 RTM"     
    return $ReturnCode
}

function DownloadPreReqs()
{
    Try
    {
        # Check if destination path exists
        If (Test-Path $SharePoint2016RTMPath)
        {
           # Remove trailing slash if it is present
           $script:SharePoint2016RTMPath = $SharePoint2016RTMPath.TrimEnd('\')          
        }
        Else {
           Write-Host "`nYour specified download path does not exist. Proceeding to create same."
           New-Item -ItemType Directory -Path $SharePoint2016RTMPath
        } 
        $returncode = DownLoadPreRequisites
        if($returncode -ne 0)
        {
            Write-Host "Unable to download all files."
        }
    }
    Catch
    {
        Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Error "Exception Message: $($_.Exception.Message)"        
    }
    finally
    {
        Write-Host ""
        Write-Host "Script execution is now complete!"
        Write-Host ""
    } 
}

DownloadPreReqs

#Install PreReqs

Start-Process "$PreRequsInstallerPath\PrerequisiteInstaller.exe" -Wait -ArgumentList "  `
              /SQLNCli:`"$PreRequsFilesPath\sqlncli.msi`" `
              /idfx11:`"$PreRequsFilesPath\MicrosoftIdentityExtensions-64.msi`" `
              /Sync:`"$PreRequsFilesPath\Synchronization.msi`" `                                                                                 
              /AppFabric:`"$PreRequsFilesPath\WindowsServerAppFabricSetup_x64.exe`" `
              /kb3092423:`"$PreRequsFilesPath\AppFabric-KB3092423-x64-ENU.exe`" `
              /MSIPCClient:`"$PreRequsFilesPath\setup_msipc_x64.exe`" `
              /wcfdataservices56:`"$PreRequsFilesPath\WcfDataServices.exe`" `
              /odbc:`"$PreRequsFilesPath\msodbcsql.msi`" `
              /msvcrt11:`"$PreRequsFilesPath\vc_redist.x64.exe`" `
              /msvcrt14:`"$PreRequsFilesPath\vcredist_x64.exe`" `
              /dotnetfx:`"$PreRequsFilesPath\NDP46-KB3045557-x86-x64-AllOS-ENU.exe`""

# Create Accounts MIMMA,MIMSync,MIMService,MIMSP,MIMAdmin

Import-Module ActiveDirectory
Write-Verbose "Lets Create the OU Path where the user is placed" -Verbose 
New-ADOrganizationalUnit -Name $Dn_Company -Path $Dn_Root
New-ADOrganizationalUnit -Name $OU -Path $Dn_Company_Path

Write-Verbose "Lets Create the user account in the domain" -Verbose 

$sp = ConvertTo-SecureString $passwdMIMMA -asplaintext -force
New-ADUser -SamAccountName $MIMMA -name $MIMMA -Path $path
Set-ADAccountPassword -identity $MIMMA -NewPassword $sp
Set-ADUser -identity $MIMMA -Enabled 1 -PasswordNeverExpires 1

$sp = ConvertTo-SecureString $passwdMIMSync -asplaintext -force
New-ADUser -SamAccountName $MIMSync -name $MIMSync -Path $path
Set-ADAccountPassword -identity $MIMSync -NewPassword $sp
Set-ADUser -identity $MIMSync -Enabled 1 -PasswordNeverExpires 1

$sp = ConvertTo-SecureString $passwdMIMService -asplaintext -force
New-ADUser -SamAccountName $MIMService -name $MIMService -Path $path
Set-ADAccountPassword -identity $MIMService -NewPassword $sp
Set-ADUser -identity $MIMService -Enabled 1 -PasswordNeverExpires 1

$sp = ConvertTo-SecureString $passwdMIMSP -asplaintext -force
New-ADUser -SamAccountName $MIMSP -name $MIMSP -Path $path
Set-ADAccountPassword -identity $MIMSP -NewPassword $sp
Set-ADUser -identity $MIMSP -Enabled 1 -PasswordNeverExpires 1

$sp = ConvertTo-SecureString $passwdMIMAdmin -asplaintext -force
New-ADUser -SamAccountName $MIMAdmin -name $MIMAdmin -Path $path
Set-ADAccountPassword -identity $MIMAdmin -NewPassword $sp
Set-ADUser -identity $MIMAdmin -Enabled 1 -PasswordNeverExpires 1 

$sp = ConvertTo-SecureString $passwddbManagedAccount -asplaintext -force
New-ADUser -SamAccountName $dbManagedAccount  -name $dbManagedAccount -Path $path
Set-ADAccountPassword -identity $dbManagedAccount  -NewPassword $sp
Set-ADUser -identity $dbManagedAccount  -Enabled 1 -PasswordNeverExpires 1 

# Create Groups

Write-Verbose "Lets Create the user Groups account" -Verbose 
New-ADGroup -name "MIMSyncAdmins" GroupCategory Security -GroupScope Global -SamAccountName "MIMSyncAdmins" -Path $path
New-ADGroup -name "MIMSyncOperators" GroupCategory Security -GroupScope Global -SamAccountName "MIMSyncOperators" -Path $path
New-ADGroup -name "MIMSyncJoiners" GroupCategory Security -GroupScope Global -SamAccountName "MIMSyncJoiners" -Path $path
New-ADGroup -name "MIMSyncBrowse" GroupCategory Security -GroupScope Global -SamAccountName "MIMSyncBrowse" -Path $path
New-ADGroup -name "MIMSyncPasswordSet" GroupCategory Security -GroupScope Global -SamAccountName "MIMSyncPasswordSet" -Path $path
Add-ADGroupMember -identity "MIMSyncAdmins" -Members $MIMAdmin
Add-ADGroupmember -identity "MIMSyncAdmins" -Members $MIMService
Add-ADGroupmember -identity "MIMSyncBrowse" -Members $MIMService
Add-ADGroupmember -identity "MIMSyncPasswordSet" -Members $MIMService

# Temorary fix $MIMService can not start Forfront Identity Manager Service
Add-LocalGroupMember -Group "Administrators" -Member $MIMService
Add-LocalGroupMember -Group "Administrators" -Member $dbManagedAccount 


# Try to add $dbManagedAccount to $SqlServer Note done yet
#Enter-PSsession <ComputerName>
#Add-LocalGroupMember -Group "Administrators" -Member <ComputerName>
# 1
#Invoke-Command -ComputerName $SqlServer -ScriptBlock {Add-LocalGroupMember -Group "Administrators" -Member $dbManagedAccount}

# SetSPN 
# To be dev I function that Check how many SPN there is and add those

setspn -S $setspn1
setspn -S $setspn2
setspn -S $setspn3
setspn -S $setspn4

# Prepare Server

Add-WindowsFeature NET-HTTP-Activation,NET-Non-HTTP-Activ,NET-WCF-Pipe-Activation45,NET-WCF-HTTP-Activation45,Web-Server,Web-WebServer,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-App-Dev,Web-Asp-Net,Web-Asp-Net45,Web-Net-Ext,Web-Net-Ext45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Security,Web-Basic-Auth,Web-Windows-Auth,Web-Filtering,Web-Digest-Auth,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Web-Lgcy-Scripting,Windows-Identity-Foundation,Xps-Viewer -source $source
Add-WindowsFeature  rsat-ad-powershell,rsat-adds-tools -source $source
iisreset /STOP

C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:windowsAuthentication -commit:apphost
iisreset /START

#Install Sharepoint Trail Serial RTNGH-MQRV6-M3BWQ-DB748-VH7DM

## Start sharepoint installer

$cmd = "$PreRequsInstallerPath\setup.exe"
invoke-expression $cmd 

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'Wait for `Sharepoint installer'
$msg   = 'Is it done yet '

$text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

#Read-Host "Press ENTER"  #Easy Pause to be removed

# Install in Synchronization Service powershell

$cmd = "MSIEXEC /i $SynchronizationServiceExe SERVICEACCOUNT=$MIMSync SERVICEPASSWORD=$PasswdMIMSync SERVICEDOMAIN=$env:USERDOMAIN GROUPADMINS=$MIMAdmin GROUPOPERATORS= MIMSyncOperators GROUPACCOUNTJOINERS= MIMSyncJoiners GROUPBROWSE=MIMSyncBrowse GROUPPASSWORDSET=MIMSyncPasswordSet ACCEPT_EULA=1 FIREWALL_CONF=1 ADDLOCAL=ALL SQMOPTINSETTING=1 REBOOT=ReallySuppress /l*v $syncLofFile"
invoke-expression $cmd 

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'Microsoft Identity Manager 2016 -Synchroniation Service'
$msg   = 'Is it done yet '

$text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

# Configure in sharepoint powershell

Add-PSSnapin Microsoft.SharePoint.PowerShell

$dbManagedAccount = Get-SPManagedAccount -Identity $SPdbManagedAccount
New-SpWebApplication -Name $SPPortalName -ApplicationPool $SPApplicationPool -ApplicationPoolAccount $dbManagedAccount -AuthenticationMethod $SPAuthenticationMethod -Port $Port -Url $SPUrl
$t = Get-SPWebTemplate -CompatibilityLevel $CompatibilityLevel -Identity "STS#1"
$w = Get-SPWebApplication $SPWeb
New-SPSite -Url $w.Url -Template $t -OwnerAlias $OwnerAlias -CompatibilityLevel $CompatibilityLevel -Name $SPPortalName -SecondaryOwnerAlias $SecondaryOwnerAlias
$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
$contentService.ViewStateOnServer = $false;
$contentService.Update();
Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job | disable-SPTimerJob
New-SPAlternateURL -WebApplication $SPPortalName -Url $New_SPAlternateURL -Zone $Ie_Zone


#$dbManagedAccount = Get-SPManagedAccount -Identity $SPdbManagedAccount
#New-SpWebApplication -Name "MIM Portal" -ApplicationPool "MIMAPPPool" -ApplicationPoolAccount $dbManagedAccount -AuthenticationMethod "Kerberos" -Port 80 -Url $SPUrl
#$t = Get-SPWebTemplate -CompatibilityLevel 15 -Identity "STS#1"
#$w = Get-SPWebApplication $SPWeb
#New-SPSite -Url $w.Url -Template $t -OwnerAlias $OwnerAlias -CompatibilityLevel 15 -Name "MIM Portal" -SecondaryOwnerAlias $SecondaryOwnerAlias
#$contentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService;
#$contentService.ViewStateOnServer = $false;
#$contentService.Update();
#Get-SPTimerJob hourly-all-sptimerservice-health-analysis-job | disable-SPTimerJob
#New-SPAlternateURL -WebApplication "MIM Portal" -Url http://localhost -Zone intranet

## Install sharepoint portal

$cmd = "MSIEXEC /i $PortalPath MAIL_SERVER=$MAIL_SERVER SQLSERVER_SERVER=$SQLSERVER_SERVER SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME SERVICE_ACCOUNT_PASSWORD=$SERVICE_ACCOUNT_PASSWORD SERVICE_ACCOUNT_DOMAIN=$SERVICE_ACCOUNT_DOMAIN SERVICE_ACCOUNT_EMAIL=$SERVICE_ACCOUNT_EMAIL RUNNING_USER_EMAIL=$RUNNING_USER_EMAIL SYNCHRONIZATION_SERVER_ACCOUNT=$SYNCHRONIZATION_SERVER_ACCOUNT SYNCHRONIZATION_SERVER=$SYNCHRONIZATION_SERVER SERVICEADDRESS=$SERVICEADDRESS SHAREPOINTUSERS_CONF=1 REGISTRATION_ACCOUNT=$REGISTRATION_ACCOUNT REGISTRATION_ACCOUNT_PASSWORD=$REGISTRATION_ACCOUNT_PASSWORD REGISTRATION_PORT=8087 REGISTRATION_SERVERNAME=$REGISTRATION_SERVERNAME IS_REGISTRATION_EXTRANET=Extranet REGISTRATION_PORTAL_URL=$REGISTRATION_PORTAL_URL RESET_ACCOUNT=$RESET_ACCOUNT RESET_ACCOUNT_PASSWORD=$RESET_ACCOUNT_PASSWORD RESET_PORT=8088 RESET_SERVERNAME=$RESET_SERVERNAME IS_RESET_EXTRANET=Extranet SHAREPOINT_URL=$SHAREPOINT_URL ACCEPT_EULA=1 FIREWALL_CONF=1 SQMOPTINSETTING=1 ADDLOCAL=ALL REMOVE=PAMServices MIMPAM_ACCOUNT_DOMAIN=$MIMPAM_ACCOUNT_DOMAIN REBOOT=ReallySuppress /l*v $PortalLogPath"
invoke-expression $cmd
