New-NetFirewallRule -DisplayName 'Everest TcpPortTracker' -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('8000')
New-NetFirewallRule -DisplayName 'Everest Docker SSH Port Redirects' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 610-630
sc.exe create TcpPortTracker start=auto binpath=c:\TcpPortTrackerService.exe
sc.exe start TcpPortTracker