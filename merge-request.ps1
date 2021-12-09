#  TODO - automated log cleanup and backup

$fso = New-Object -com "Scripting.FileSystemObject"
$gitlab_path = "Z:\Downloads\Chromium\New folder (2)"
$logfile = "$gitlab_path\gitlab-merge-request-cleanup.log"

If (-not (Test-Path -Path $gitlab_path)){
    $logfile = "C:\Temp\gitlab-merge-request-cleanup.log"
}

Function log-write
{
   Param ([string]$logstring)

   $stamp = (Get-Date).toString("MM/dd/yyyy HH:mm:ss")
   $line = "$stamp $logstring"


   Add-content $Logfile -value $line
}

If (Test-Path -Path $gitlab_path){
    $folder = $fso.GetFolder($gitlab_path)
    $deleted = 0
    foreach ($subfolder in $folder.SubFolders){
        If ($subfolder.Name -match ".+_MR-\d+-.+"){ #.+_MR-\d{2,}-.+
            $deleted = 1
            $folder_path = convert-path $subfolder.Path
            $items = Get-ChildItem $subfolder.Path -Recurse 
            $most_recent_file = $items | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            IF(($most_recent_file).LastWriteTime -lt  (Get-Date).AddMinutes(-30)){
                remove-item $subfolder.Path -Verbose -Recurse -Force
                log-write "Removing folder [$folder_path] and all subfiles and folders." 
            }
            Else{
                log-write "Merge Request found younger than 30 minutes. Skipping folders and files."
            }
            
            # Get-ChildItem -Path $subfolder.Path -Include * -File -Recurse | foreach { $_.Delete()}
            # Get-ChildItem -Path $subfolder.Path -Include *.* -File -Recurse | foreach { $_.Delete()}
            # remove-item $subfolder.Path -Verbose -Recurse -Force
            
        }       
    }
    If (-not($deleted)){
        log-write "GitLab Merge Request Cleanup has been run. No folders to clean up have been found."
    }
    Else{
        log-write "GitLab Merge Request Cleanup has completed."
    }
}
Else {
    log-write "Gitlab Folder not found. Please check filepath. Expecting: [$gitlab_path]."
}
