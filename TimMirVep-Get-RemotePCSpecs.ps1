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
    ./TimMirVep-Get-RemotePCSpecs.ps1 Win10-C1 Win10-C2
    Return dans un fichier logs se trouvant dans un dossier logs :
    DATE | Carte mère | Processeur | Carte graphique - VRAM | RAM | Quantité - Type | Disque dur | Espace des PC 
    Exemple : 20.04.2020 | ASRock Z390 Taichi Ultimate | I9-9900K - 3.6GHz | RTX2080TI - 11GB | Admin Administrateur Win10Client | SSD Samsung EVO 860 - 500Gb
#>

#Affichage de l'aide du script si l'utilisateur n'a pas entré de noms de PC
if (!$args)
{
    Get-Help $MyInvocation.MyCommand.Path
    exit
}
else
{
    #Création d'un tableau d'erreurs (ce qui va être inscrit dans le fichier d'erreurs)
    $errors=@()

    #Vérification de si l'utilisateur qui exécute le script dispose des droits d'administrateur
    if ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')
    {
        #Création d'un tableau de logs (ce qui va être inscrit dans le fichier de logs)
        $logs=@()

        #Reprend la date lors de l'exécution du script
        $date = Get-Date

        #Date dans les logs
        $dateSpec = $date.ToString("dd.MM.yyyy")

        #Date pour le nom du fichier de logs
        $date = $date.ToString("yyyy-MM-dd-HH-mm-ss")

        #Chemin où se situe le script sur la machine
        $path = (Get-Location).path
        
        #Chemin du dossier logs
        $logFolder = "$path\logs"
   
        #Créé le dossier logs à l'emplacement où le script se situe sur la machine
        New-Item -Path $logFolder -ItemType Directory -ErrorAction Ignore

        #Check si problème de création du dossier
        if (!$?)
        {
            $errors += "Le dossier logs n'a pas été créé car il existe déjà à cet emplacement."
        }

        #Stockage du chemin de fichier de logs
        $logPath = "$logFolder\$date-logs.txt"

        #Stockage du chemin de fichier d'erreurs
        $errorPath = "$logFolder\$date-errors.txt"

        #En-tête fichier logs
        $logs += "DATE | Carte mère | Processeur | Carte graphique - VRAM | Comptes Admin. | Disque dur - Espace"

        foreach ($PC in $args)
        {
            #Suppression de la session de remoting au cas où il y ait plusieurs comptes et que la session ne soit pas modifiée
            $remotingSession = $NULL

            try
            {
                #Création d'une session en entrant des informations de connexion pour un compte (droits admins nécessaires)
                $cred=Get-Credential

                #Création de la session
                $remotingSession = New-PSSession -ComputerName $PC -Credential $cred -ErrorAction Ignore
            }
            catch
            {
                $errors += "Aucune informations de session pour le PC $PC n'ont été entrées."
            }

            if (!($NULL -eq $remotingSession))
            {
                #Récupération des informations si la session a pu être établie
                
                #Récupération des informations de la carte mère
                $moboManufacturer = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_BaseBoard).Manufacturer}
                $moboProduct = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_BaseBoard).Product}
                
                #Récupération des informations du processeur
                $cpuName = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-CimInstance CIM_Processor).Name}
                $cpuClock = [string](Invoke-Command -Session $remotingSession -ScriptBlock{(Get-CimInstance CIM_Processor).MaxClockSpeed/1000})
                #Arrondi de la vitesse du processeur à 1 décimale + texte
                $cpuClock = [string]([math]::round($cpuClock, 1)) + "GHz";

                #Récupération des informations de la carte graphique du PC
                $gpuName = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_VideoController).Name}
                $gpuVram = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_VideoController).AdapterRAM/1gb}
                #Arrondi de la Mémoire vive de la carte à 1 décimale + texte
                $gpuVram = [string]([math]::round($gpuVram, 1)) + "GB"

               
                #Récupération de tous les comptes ayant un droit d'admn
                #https://www.tutorialspoint.com/how-to-get-the-local-administrators-group-members-using-powershell
                $adminAccounts = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-LocalGroupMember -Group "Administrateurs"| where {$_.ObjectClass -eq "Utilisateur"}).Name}

                #Remise à 0 du tableau avec le nom d'administrateurs (suppression des noms déjà existants si déjà exécuté une fois)
                $adminNames = @()

                #Récupération de uniquement le nom de l'utilisateur ayant le droit
                foreach ($admin in $adminAccounts) {
                    #Séparation du nom de de celui du PC ("PC\Utilisateur" -> "PC", "Utilisateur")
                    #https://linuxhint.com/split-strings-powershell/
                    $adminTemp = $admin.Split('\') 
                    
                    #Ajout du nom de l'utilisateur dans un tableau
                    $adminNames += $adminTemp[1]
                }

                #Récupération du disque dur principal de la machine (celui actif)
                $diskModel = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_DiskDrive | where {$_.DeviceID -eq "\\.\PHYSICALDRIVE0"}).Model}

                #Récupération de l'espace disque en GB sur la machine
                #https://www.improvescripting.com/how-to-get-disk-size-and-disk-free-space-using-powershell
                #https://ardamis.com/2012/08/21/getting-a-list-of-logical-and-physical-drives-from-the-command-line/
                $diskGb = Invoke-Command -Session $remotingSession -ScriptBlock{(Get-WmiObject Win32_DiskDrive | where {$_.DeviceID -eq "\\.\PHYSICALDRIVE0"}).Size/1gb}

                #Arrondi de l'espace du disque dur en Gb + ajout texte
                #https://devblogs.microsoft.com/scripting/powertip-use-powershell-to-round-to-specific-decimal-place/
                $diskGb = [string]([math]::Round($diskGb, 0)) + "Gb" 

                #Mise en forme des informations récupérées en une seule ligne
                $logs += "$PC : $dateSpec | $moboManufacturer $moboProduct | $cpuName - $cpuClock | $gpuName - $gpuVRAM | $adminNames | $diskModel - $diskGB"
            } #endif session non nulle
            else
            {
                $errors += "La session sur le PC $PC n'a pas pu être établie et les informations n'ont pas pu être récupérées."
            }
        }

        #Ecriture de toutes les erreurs dans le dossier logs 
        foreach ($error in $errors) {
            Write-Output "$error" >> $errorPath
        }
        
        #Ecriture de toutes les informations récupérées dans le dossier logs
        foreach ($log in $logs) {
            Write-Output "$log" >> $logPath
        }
    } #endif Admin rights check
    else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "Vous devez exécuter ce script avec les droits d'administrateur."
    }
} #endif (!$args)




