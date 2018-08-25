$Error.Clear()
$LastExitCode = 0

$cygpath = c:\cygwin64\bin\cygpath.exe -u ${pwd}
$cmd = "cd $cygpath && $args"
Write-Host "Command to execute: " $cmd

c:\cygwin64\bin\bash.exe --login -c "$cmd"

if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    Write-Host "*** Error:"
    $Error
    exit 1
}