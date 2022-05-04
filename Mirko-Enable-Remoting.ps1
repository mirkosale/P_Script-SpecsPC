<#
.NOTES
    *****************************************************************************
    ETML
    Name:	TimMirVep-Get-RemotePCSpecs.ps1
    Author:	Tim Froidevaux (pg44yzv)
			Veprim Kadirolli (vepkadiroll)
			Mirko Sale (pb51vab)
    Date:	25.05.2022
 	*****************************************************************************
    Modifications
 	Date  : -
 	Author: -
 	Reason: -
 	*****************************************************************************

.SYNOPSIS
    Autorise le remoting sur une machine
 	
.DESCRIPTION
    Va vérifier si l'utilisateur a des droits d'administrateur, va autoriser le
	remoting sur un machine et va ensuite redémarrer le PC.
 #>

#Check for administrator rights
if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
{
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
    Set-Item WSMan:\localhost\Client\TrustedHosts *
    Restart-Service winrm
    shutdown -r -t 30
} #endif Admin rights check
else
{
    Write-Host -ForegroundColor Yellow -BackgroundColor Black "You need to run this script with Administrator Privileges for it to work."
}
