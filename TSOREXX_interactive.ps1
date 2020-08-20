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

# Zowe CLI command to start a TSO address space
# --sko     : option to print only the servlet key (need this for subsequest communications)
# --zosmf-p : z/OSMF profile to use for authentication
# --tso-p   : TSO profile to use when creating the TSO address space
$addressSpaceKey = zowe tso start address-space --sko --zosmf-p $zosmfProfile --tso-p $tsoProfile

if ($null -ne $addressSpaceKey ) {
    # Send data to the TSO address space 

    # Zowe CLI command to send a TSO address space
    # --data    : data to send to the address space specified by the servley key
    # --zosmf-p : z/OSMF profile to use for authentication            
    # --rfj     : return the response in JSON format
    $tempOutput = zowe tso send as $addressSpaceKey --data "exec '$rexxFile'" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
    Checkpoint-ErrorHandling -output $tempOutput

    # Run a loop to sequentially reply to all prompts
    # Make sure the number of prompts matches the number of inputs in your array

    foreach ($input in $params.tsorexx.inputs) {
        Write-Host "INPUT: $($input)"
        $tempOutput = zowe tso send address-space $addressSpaceKey --data "$($input)" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
        Checkpoint-ErrorHandling -output $tempOutput
        # Break the loop so we don't use the second input (to match the behavior in the REXX script)
        if ($tempOutput.stdout -ne "HELLO ALEX, HOW OLD ARE YOU?`n`n") {Break}
    }
} else {
    throw "Opening TSO address space failed!"
}

# Zowe CLI command to stop a TSO address space
# --zosmf-p : z/OSMF profile to use for authentication
zowe tso stop address-space $addressSpaceKey --zosmf-p $zosmfProfile | Out-Null