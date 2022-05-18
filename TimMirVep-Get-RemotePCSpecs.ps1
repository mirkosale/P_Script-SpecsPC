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
    Exemple : 20.04.2020 | ASRock Z390 Taichi Ultimate | I9-9900K - 3.6GHz | RTX2080TI - 11GB | Corsair - 32GB - DDR4 | SSD Samsung EVO 860 - 500Gb
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
    $logs=@()

    #Check for administrator rights
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
    {
        #Reprend la date lors de l'ex�cution du script
        $date = Get-Date
        $dateSpec = $date.ToString("dd.MM.yyyy")
        $date = $date.ToString("yyyy-MM-dd-HH-mm-ss")

        #Chemin du script
        $path = (Get-Location).path
        
        #Chemin du dossier
        $logFolder = "$path\logs"
   
        New-Item -Path $logFolder -ItemType Directory -ErrorAction Ignore
        if (!$?)
        {
            $errors += "Le dossier logs existe d�j� � cet emplacement"
        }

        #Chemin du fichier
        $logPath = "$logFolder\$date-logs.txt"
        $errorPath = "$logFolder\$date-errors.txt"

        foreach ($PC in $args)
        {
            try
            {
                $cred=Get-Credential
                $remotingSession = New-PSSession -ComputerName $PC -Credential $cred
            }
            catch
            {
                $errors += "La session n'a pas pu �tre cr��e sur le PC $PC car les identifiants sont incorrects ou la machine n'existe pas."
            }

            Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_ComputerSystem).Name | Write-Output >> $filePath}
            $logs += "DATE | Carte m�re | Processeur | Carte graphique - VRAM | RAM - Quantit� - Type | Disque dur - Espace"
            

            #R�cup�ration des informations si la session a pu �tre �tablie
          

               

                $moboManufacturer = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_BaseBoard).Manufacturer}
                $moboProduct = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_BaseBoard).Product}
                $cpuName = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-CimInstance CIM_Processor).Name}
                $cpuClock = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-CimInstance CIM_Processor).MaxClockSpeed}

                $diskModel = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_DiskDrive | where {$_.DeviceID -eq "\\.\PHYSICALDRIVE0"}).Model}
                #
                #https://www.improvescripting.com/how-to-get-disk-size-and-disk-free-space-using-powershell
                #https://ardamis.com/2012/08/21/getting-a-list-of-logical-and-physical-drives-from-the-command-line/
                $diskGb = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_DiskDrive | where {$_.DeviceID -eq "\\.\PHYSICALDRIVE0"}).Size/1gb}
                #
                #https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-round-to-specific-decimal-place/
                $diskGb = [string]([math]::Round($diskGb, 0)) + "Gb" 
                $VRAM = Invoke-Command -Session $remotingSession -ScriptBlock{Get-WmiObject Win32_VideoController | select name, AdapterRAM,@{Expression={$_.adapterram/1GB};label="GB"}}
                
                $logs += "$PC : $dateSpec | $moboManufacturer $moboProduct | $cpuName - $cpuClock | $gpuName - $gpuVRAM | $ramName - $ramAmount - $ramType | $diskModel - $diskGB"
            # if ($remotingSession -eq $null)
            # {
            #     echo a  }
            else
            {
                $errors += "Erreur session"
            }
        }

        foreach ($error in $errors) {
            Write-Output "$error" >> $errorPath
        }
        
        foreach ($log in $logs) {
            Write-Output "$log" >> $logPath
        }
    } #endif Admin rights check
    else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "You need to run this script with Administrator Privileges for it to work."
    }
} #endif (!$args)




