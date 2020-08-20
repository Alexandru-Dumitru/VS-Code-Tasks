Import-Module './helper-functions' 

Write-Host "Running on remote system. Waiting for output..."

# Loading params from json file
$params = Get-Content '.\params.json' | ConvertFrom-JSON

# check if zosmf profile is passed from task, if not, take it from params
if  ($args[1]) {
    $zosmfProfile = $args[1]
} else {
    $zosmfProfile = $params.tsorexx.zosmfProfile
}

# check if tso profile is passed from task, if not, take it from params
if  ($args[2]) {
    $tsoProfile = $args[2]
} else {
    $tsoProfile = $params.tsorexx.tsoProfile
}

$rexxFile = Get-Remote_FilePath -localFilePath $args[0]

# Zowe CLI command to run a REXX script in a TSO address space
# --ssm     : supresses startup messages
# --rfj     : returns the output in JSON format
# --zosmf-p : z/OSMF profile to use for authentication
# --tso-p   : TSO profile to use when creating the TSO address space
$output = zowe tso issue command "exec '$rexxFile'" --ssm --rfj --zosmf-p $zosmfProfile --tso-p $tsoProfile | ConvertFrom-JSON

# Basic error handling

# Zowe command error handling
if ($null -ne $output -And $output.exitCode -ne 0) {
    throw $($output.message)
}

# REXX error handling
$RCregex = '(RC\(-\d\))'
$RCcoderegex = '-\d'
$hasRCinOutput = [regex]::match($output.stdout,$RCregex).Groups[1].Success
$value = [regex]::match($output.stdout,$RCregex).Groups[1].Value
$RC = [regex]::match($value,$RCcoderegex).Value

if (-Not $hasRCinOutput) {
    Write-Host 
    Write-Host "OUTPUT:"
    Write-Host 
    Write-Host $output.stdout
    # Write-Host $output.data.zosmfResponse.tsoData
} else {
    Write-Host "REXX finished in error." 
    Write-Host "Return Code: $($RC)"
    Write-Host
    Write-Host "Full output follows:"
    Write-Host
    Write-Host $output.stdout
}