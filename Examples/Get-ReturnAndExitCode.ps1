# Cmdlet binding is required for the $PSCmdlet variable to be present
[CmdletBinding()]
# Cmdlet binding requires a param statement to properly bind.
param(
    # Whatever params you want here.
    # Script does not actually have to have params.
)

# The object is returned/pushed here, if a .net compatible system can take the data, it will be available.
# Unlike the return statement, this does not exit execution, it only pushes data.
# It is designed this way to support the parallel execution capability of the pipeline.

# If you want to stop execution without killing your script, use the "break" key word.
# it works for the current scope of execution, not just loops.
# The "exit" key word will stop the current script execution, not the entire process.
$PSCmdlet.WriteObject(@{elliot=123})
$PSCmdlet.WriteObject(@{huffman=456})

# Set an exit code, if another script had called this one, this number is lost, the other script will need to specify an error code
# If this script stops the powershell process with the exit statement, this is the %errorlevel%/exit code that will be used
exit 125