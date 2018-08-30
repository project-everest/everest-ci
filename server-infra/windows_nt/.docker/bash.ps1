function global:Invoke-BashCmd
{
    $Error.Clear()
    $LastExitCode = 0

    Write-Host "Args:" $args

    # Escape quotes
    $args = $args -replace '"','""'
    $args = $args -replace "'",'""'

    # Exec command
    $outputFile = "output.txt"
    $cygpath = c:\cygwin64\bin\cygpath.exe -u ${pwd}
    c:\cygwin64\bin\bash.exe --login -c "cd $cygpath && $args" | Out-File $outputFile

    If ((Test-Path $outputFile) -eq $true) {
        Get-Content $outputFile -Raw | Write-Output
        Remove-Item $outputFile -Force
    }

    if ($Error.Count -gt 0 -or $LastExitCode -ne 0) {
        Write-Host "*** Error:"
        $Error
        exit 1
    }
}

function global:New-BashCmdProfile
{
    cat bash.ps1 >> $profile.AllUsersCurrentHost
}