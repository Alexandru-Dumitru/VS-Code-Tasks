# Extracting the remote file path from local file downloaded by Zowe Explorer
function Get-Remote_FilePath {
    param (
        [Parameter(Mandatory=$true)] [String]$localFilePath
    )
    
    $parent = Split-Path $localFilePath -Parent
    $parentArray = $parent.Split("\")
    # _U_ is the default folder where zowe explorer puts Unix files
    # _D_ is the default folder where zowe explorer puts datasets files
    $idxU = $parentArray.IndexOf("_U_") 
    $idxD = $parentArray.IndexOf("_D_")

    # for datasets, we need just the dataset name without the file extension
    if ($idxD -ne -1) {
        return (Get-Item $localFilePath).BaseName
    }

    if ($idxU -ne -1) {
        $idx = $idxU
    } else {
        throw "$localFilePath is not downloaded from Zowe Explorer"
    }

    $subArray = $parentArray[($idx + 1)..($parentArray.Count-1)]
    $ofs = "/"
    
    # remove system name 
    $remoteParentPath = $subArray.Split("/")[1..$subArray.Count]
    # construct remote file path
    $fileName = Split-Path $localFilePath -Leaf
    $remoteFilePath = "$remoteParentPath/$fileName"
    return "/$remoteFilePath"
}

# Extracts the member name from the local filename syntax
function Get-Member_Name {
    param (
        [Parameter(Mandatory=$true)] [String]$localFilePath
    )

    $fileName = Split-Path $localFilePath -Leaf
    $memberName = [regex]::match($fileName,'\(([^\)]+)\)').Groups[1].Value
    return "$memberName"
}

# Clean up function that removes temp JCL file and spool files
function Remove-Files {
    param (
        [Parameter(mandatory=$true)]  [String]$jobid,
        [Parameter(mandatory=$false)]  [Bool]$keepSpool = $False,
        [Parameter(mandatory=$false)]  [String]$outputJcl = './output.jcl'
    )
    # Delete output.jcl file
    # In case you submit a remote dataset this file is not created, 
    # so we ignore the "file not found" error
    Remove-Item -Path $outputJcl -ErrorAction Ignore

    # Delete spool files (by default)
    if(-Not $keepSpool) {
        Remove-Item -Path $jobid -Recurse
    } else {
        Write-Host
        Write-Host "Additional Information:"
        Write-Host "Spool files are kept under folder: $jobid"
    }
}

Export-ModuleMember -Function Get-Remote_FilePath
Export-ModuleMember -Function Get-Member_Name
Export-ModuleMember -Function Remove-Files
