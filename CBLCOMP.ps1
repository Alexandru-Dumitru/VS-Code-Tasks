Import-Module './helper-functions' 

Write-Output "Running on remote system. Waiting for output..."

# Loading params from json file
$params = Get-Content '.\params.json' | ConvertFrom-JSON

# Another approach is to submit remote JCLs. 
# This assumes the structure of the project is as follows:
# HLQ.CBL(MEMBER)
# HQL.JCL(MEMBER)
# and there is a 1 to 1 parity for the memeber names,
# we can just extract the member name from CBL dataset 
# and use it to submit the JCL counterpart. 

# This approach was tailored for OMP COBOL course

$memberName = Get-Member_Name -localFilePath $args[0]
# adjust for deviation in COBOL course (some JCL files have a J appended to the name)
if ($memberName.StartsWith("CBL00")) {
    $memberName = $memberName + "J"
}
$fullMemberName = "$(($params.cblcomp.jobCard.username)).JCL($memberName)"

# check if profile is passed from task, if not, take it from params
if  ($args[1]) {
    $profile = $args[1]
} else {
    $profile = $params.cblcomp.defaultProfile
}

# Zowe CLI command to submit a dataset and get back the spool files
# --directory . - signals the command to download all spool files in current directory
# --rfj`        - gets the return of the command in JSON format
# --zosmf-p     - z/OSMF profile to use when submitting the command  
$output = zowe jobs submit ds $fullMemberName --directory . --rfj --zosmf-p $profile | ConvertFrom-JSON

$jobid = $output.data.jobid
$keepSpool = [System.Convert]::ToBoolean($params.cblcomp.keepSpool)

# Basic error handling
if ($output.data.retcode -eq "CC 0000") {
    Write-Host ""
    Write-Host "OUTPUT:"
    # I have multiple output paths in the params.json file
    # Depending on the job, there could be a different output that I am interested in
    # This is a lazy way of displaying it regardless if the file is present or not
    Get-Content -Path ".\$jobid$($params.cblcomp.defaultStdout)" -ErrorAction Ignore
    Get-Content -Path ".\$jobid$($params.cblcomp.prtline)" -ErrorAction Ignore
    Remove-Files -jobid $jobid -keepSpool $keepSpool -outputJcl $params.cblcomp.outputJcl
} else {
    Write-Host "JOB $($output.data.jobid) finished in error." 
    Write-Host "Return Code: $($output.data.retcode)"
    Remove-Files -jobid $jobid -keepSpool $keepSpool -outputJcl $params.cblcomp.outputJcl
}

