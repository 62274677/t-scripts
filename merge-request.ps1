#  TODO - automated log cleanup and backup

$fso = New-Object -com "Scripting.FileSystemObject"
$gitlab_path = "C:\CHANGE\THIS\PATH\Gitlab\MergeRequests"
$logfile = "$gitlab_path\gitlab-merge-request-cleanup.log"

If (-not (Test-Path -Path $gitlab_path)){ # If hard-coded gitlab folder does not exist
    $logfile = "C:\Temp\gitlab-merge-request-cleanup.log" # create cleanup.log in C:/Temp directory
}

Function log-write # Function to write logs to file (can be further standardized)
{
   Param ([string]$logstring)

   $stamp = (Get-Date).toString("MM/dd/yyyy HH:mm:ss")
   $line = "$stamp $logstring"


   Add-content $Logfile -value $line
}

If (Test-Path -Path $gitlab_path){ # If Gitlab path exists
    $folder = $fso.GetFolder($gitlab_path)
    $deleted = 0
    foreach ($subfolder in $folder.SubFolders){ # For each folder in the hardcoded root directory:
        If ($subfolder.Name -match ".+_MR-\d+-.+"){ #.+_MR-\d{2,}-.+ 
                                                    # If the folder name matches a Merge Request:

            $deleted = 1
            $folder_path = convert-path $subfolder.Path
            $items = Get-ChildItem $subfolder.Path -Recurse 
            $most_recent_file = $items | Sort-Object LastWriteTime -Descending | Select-Object -First 1 
                                                            # Get the most recently edited file in the subdirectory
            If(($most_recent_file).LastWriteTime -lt  (Get-Date).AddMinutes(-30)){  # If the most recent edit is older than 30 minutes:
                                                                                    # Delete all files in current subdirectory
                remove-item $subfolder.Path -Verbose -Recurse -Force
                log-write "Removing folder [$folder_path] and all subfiles and folders." 
            }
            Else{ # Else if merge requests found with files younger than 30 minutes, do nothing
                log-write "Merge Request found younger than 30 minutes. Skipping folders and files."
            }
            
            # Get-ChildItem -Path $subfolder.Path -Include * -File -Recurse | foreach { $_.Delete()}
            # Get-ChildItem -Path $subfolder.Path -Include *.* -File -Recurse | foreach { $_.Delete()}
            # remove-item $subfolder.Path -Verbose -Recurse -Force
            
            
        }  # Repeat
    }
    If (-not($deleted)){ # If the script doesn't find any files to delete, report this in the log file
        log-write "GitLab Merge Request Cleanup has been run. No folders to clean up have been found."
    }
    Else{ # If the script has found files to delete, report that it has completed.
        log-write "GitLab Merge Request Cleanup has completed."
    }
}
Else { # If the script could not find the gitlab merge folder, output to C:/Temp this message
    log-write "Gitlab Folder not found. Please check filepath. Expecting: [$gitlab_path]."
}
