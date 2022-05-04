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
    Obtenir les spécifications d'une liste de PC à distance
 	
.DESCRIPTION
    Ce script une fois exécuté va rechercher dans toute la liste de PC passée via 
    les arguments et va récupérer les informations sur le PC (telles que le 
    processeur, le nom de la machine, etc.) existants dans le réseau en vérifiant
    qu'ils existent via le nom . Ces informations vont ensuite être récupérées 
    et stockées dans un fichier texte et organisées sous forme de tableau. Ces
    informations vont ensuite être placées dans un dossier de logs avec un nom
    de fichier unique comme nom de fichier texte.
    

.OUTPUTS
	Un fichier avec les différentes informations des PCs et un fichier
    qui va répertorier les erreurs qui se sont produites.
	
.EXAMPLE
    

#>

if (!$args)
{
    Get-Help $MyInvocation.MyCommand.Path
    exit
}
else
{

    Set-Variable -Name 

    $errors=@()

    #Check for administrator rights
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
    {
        foreach ($PC in $args)
        {
            try 
            {
                $remotingSession = New-PSSession -ComputerName $PC 
            }

            catch 
            {
                $errors += ""
            }
        }



        foreach ($error in $errors) {
            Write-Output $error + "`r`n" >> $filePath
        }

    } #endif Admin rights check
    else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "You need to run this script with Administrator Privileges for it to work."
    }
} #endif (!$args)




