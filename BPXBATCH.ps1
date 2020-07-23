Import-Module './helper-functions' 

Write-Host "Running on remote system. Waiting for output..."

# Loading params from json file
$params = Get-Content '.\params.json' | ConvertFrom-JSON

$remoteFilePath = Get-Remote_FilePath -localFilePath $args[0]

# This JCL can be parametrized more, if needed
$JCL="//EXECSH   JOB $($params.bpxbatch.jobCard.account),$($params.bpxbatch.jobCard.username),
//    NOTIFY=$($params.bpxbatch.jobCard.notify),
//    MSGLEVEL=$($params.bpxbatch.jobCard.msglevel),
//    CLASS=$($params.bpxbatch.jobCard.class),
//    MSGCLASS=$($params.bpxbatch.jobCard.msgclass),
//    REGION=$($params.bpxbatch.jobCard.region),
//    USER=$($params.bpxbatch.jobCard.username)
//*********************************************************************
//* EXECSH - Execute A Shell Script using BPXBATCH                    *
//*********************************************************************
//XBATCH   EXEC PGM=BPXBATCH,REGION=0M
//STDIN    DD PATH='$remoteFilePath'
//STDOUT   DD SYSOUT=*
//STDERR   DD SYSOUT=*
//*
"
# Write the temp JCL file
Set-Content -Path $params.bpxbatch.outputJcl -Value $JCL

# check if profile is passed from task, if not, take it from params
if  ($args[1]) {
    $profile = $args[1]
} else {
    $profile = $params.bpxbatch.defaultProfile
}

# Zowe CLI command to submit a local file and get back the spool files
# --directory . - signals the command to download all spool files in current directory
# --rfj`        - gets the return of the command in JSON format
# --zosmf-p     - z/OSMF profile to use when submitting the command  
$output = zowe jobs submit local-file $params.bpxbatch.outputJcl --directory . --rfj --zosmf-p $profile | ConvertFrom-JSON

$jobid = $output.data.jobid
$keepSpool = [System.Convert]::ToBoolean($params.bpxbatch.keepSpool)

# Basic error handling
if ($output.data.retcode -eq "CC 0000") {
    Write-Host ""
    Write-Host "OUTPUT:"
    Get-Content -Path ".\$jobid$($params.bpxbatch.defaultStdout)"
    Remove-Files -jobid $jobid -keepSpool $keepSpool -outputJcl $params.bpxbatch.outputJcl
} else {
    Write-Host "JOB $($output.data.jobid) finished in error." 
    Write-Host "Return Code: $($output.data.retcode)"
    Remove-Files -jobid $jobid -keepSpool $keepSpool -outputJcl $params.bpxbatch.outputJcl
}