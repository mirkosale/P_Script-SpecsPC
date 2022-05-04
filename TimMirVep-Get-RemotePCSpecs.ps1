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
    Obtenir les sp�cifications d'une liste de PC � distance
 	
.DESCRIPTION
    Ce script une fois ex�cut� va rechercher dans toute la liste de PC pass�e via 
    les arguments et va r�cup�rer les informations sur le PC (telles que le 
    processeur, le nom de la machine, etc.) existants dans le r�seau en v�rifiant
    qu'ils existent via le nom . Ces informations vont ensuite �tre r�cup�r�es 
    et stock�es dans un fichier texte et organis�es sous forme de tableau. Ces
    informations vont ensuite �tre plac�es dans un dossier de logs avec un nom
    de fichier unique comme nom de fichier texte.
    

.OUTPUTS
	Un fichier avec les diff�rentes informations des PCs et un fichier
    qui va r�pertorier les erreurs qui se sont produites.
	
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




