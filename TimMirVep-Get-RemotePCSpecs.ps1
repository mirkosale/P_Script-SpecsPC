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
    ./TimMirVep-Get-RemotePCSpecs.ps1 Win10-C1 Win10-C2
    Return dans un fichier logs se trouvant dans un dossier logs :
    DATE | Carte m�re | Processeur | Carte graphique - VRAM | RAM | Quantit� - Type | Disque dur | Espace des PC 
    Exemple : 20.04.2020 | ASRock Z390 Taichi Ultimate | I9-9900K ? 3.6GHz | RTX2080TI ? 11GB | Corsair ? 32GB ? DDR4 | SSD Samsung EVO 860 ? 500Gb
#>

#Si l'utilisateur n'a pas entr� d'arguments
if (!$args)
{
    Get-Help $MyInvocation.MyCommand.Path
    exit
}
else
{
    $errors=@()

    #Check for administrator rights
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
    {
        #Reprend la date lors de l'ex�cution du script
        $date = Get-Date
        $date = $date.ToString("yyyy-MM-dd-HH-mm-ss")


        #Chemin du script
        $path = (Get-Location).path
        
        #Chemin du dossier
        $logPath = "$path\logs"

   
            New-Item -Path $logPath -ItemType Directory -ErrorAction Ignore
        if (!$?)
        {
            $errors += "Le dossier logs existe d�j� � cet emplacement"
        }

        #Chemin du fichier
        $filePath = "$logPath\$date-logs.txt"
        $errorPath = "$logPath\$date-errors.txt"

        foreach ($PC in $args)
        {
            try
            {
                $cred=Get-Credential -ErrorAction Ignore
                $remotingSession = New-PSSession -ComputerName $PC -Credential $cred -ErrorAction Ignore
            }
            catch
            {
                $errors += "La session n'a pas pu �tre cr��e sur le PC $PC car les identifiants sont incorrects ou la machine n'existe pas."
            }

            Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_ComputerSystem).Name | Write-Output >> $filePath}
        }



        foreach ($error in $errors) {
            Write-Output "$error `r`n" >> $errorPath
        }

    } #endif Admin rights check
    else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "You need to run this script with Administrator Privileges for it to work."
    }
} #endif (!$args)




