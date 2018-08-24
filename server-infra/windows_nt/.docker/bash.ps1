$Error.Clear()
$LastExitCode = 0

Write-Host "Arguments: " $args
$cygpath = c:\cygwin64\bin\cygpath.exe -u ${pwd}
c:\cygwin64\bin\bash.exe --login -c "cd $cygpath && $args"

if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
    $Error
    exit 1
}