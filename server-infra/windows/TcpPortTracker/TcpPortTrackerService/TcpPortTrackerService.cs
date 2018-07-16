using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.Net.NetworkInformation;
using System.ServiceModel;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;

//
// A WCF Server which manages a pool of TCP port numbers.  Docker on Windows support port remapping
// (ie. remap a container's port 22 to a different host port number).  But its remapping is either
// specific, or ephemeral.  In the case of ephmeral, there is no way to constrain the range of ports,
// and Docker doesn't seem to respect the range of Windows ephmeral ports anyhow.  Without a range
// restriction, it is difficult to open the Azure firewall and VM firewall to allow inbound connections
// to a remapped port.
//
// This service is a workaround, maintaining a pool of TCP ports.
//
// To install and launch, run this from an elevated command prompt:
//  sc create TcpPortTracker start=auto binpath=<path_to_>\TcpPortTrackerService.exe
//  sc start TcpPortTracker
// Then open ports 8000, and 610-630 in the Azure and Windows firewalls.
//
// The port range is a bit arbitrary, but isn't in the ephemeral range, and doesn't appear to be
// in common use.

namespace TcpPortTrackerService
{
    // Single-instance / Single-thread class for keeping track of a pool of TCP ports.
    [ServiceBehavior(InstanceContextMode = InstanceContextMode.Single, ConcurrencyMode = ConcurrencyMode.Single)]
    class TcpPortTracker : ITcpPortTracker
    {
        const int MinPort = 610;        // Min port # to hand out
        const int MaxPort = 630;        // Max port # to hand out
        const int RescanInterval = 5;   // Don't rescan until this many minutes has elapsed since the last call

        internal static EventLog log = null; // EventLog to write into, for this service instance

        List<int> AvailablePorts = null;    // List of available ports
        DateTime LastUse;               // Timestamp of the last use of this WCF server

        public TcpPortTracker()
        {
            RescanPortsIfNeeded();
        }

        public void FreePort(int Port)
        {
            log.WriteEntry(string.Format("FreePort: {0}", Port), EventLogEntryType.Information);
            if (!AvailablePorts.Contains(Port))
            {
                log.WriteEntry("Added to the free list", EventLogEntryType.Information);
                AvailablePorts.Add(Port);
            }
            else
            {
                log.WriteEntry(string.Format("Port is already on the free list!"), EventLogEntryType.Error);
            }
            LastUse = System.DateTime.UtcNow;
        }

        public int GetAvailablePort()
        {
            RescanPortsIfNeeded();
            log.WriteEntry("GetAvailablePort", EventLogEntryType.Information);
            if (AvailablePorts.Count == 0)
            {
                log.WriteEntry("No ports are available!", EventLogEntryType.Error);
                return -1;
            }
            int Port = AvailablePorts[0];
            AvailablePorts.RemoveAt(0);
            log.WriteEntry(string.Format("Returning port {0}.  {1} Available", Port, AvailablePorts.Count), EventLogEntryType.Information);
            return Port;
        }

        // If RescanInterval minutes has passed since the last call, rescan open TCP
        // ports, to refresh the list.  Don't refresh too often, or else a port might
        // be reclaimed before VSTS has time to create the new docker container using
        // that port number.
        void RescanPortsIfNeeded()
        {
            if ((System.DateTime.UtcNow - LastUse).TotalMinutes > RescanInterval)
            {
                ScanPorts();
            }
            LastUse = System.DateTime.UtcNow;
        }

        // Refresh the free-port list by scanning for active TCP listeners.
        void ScanPorts()
        {
            AvailablePorts = Enumerable.Range(MinPort, MaxPort-MinPort+1).ToList<int>();

            IPGlobalProperties ipGlobalProperties = IPGlobalProperties.GetIPGlobalProperties();
            TcpConnectionInformation[] tcpConnInfoArray = ipGlobalProperties.GetActiveTcpConnections();
            foreach (var c in tcpConnInfoArray) {
                if (c.LocalEndPoint.Port >= MinPort && c.LocalEndPoint.Port <= MaxPort) {
                    AvailablePorts.Remove(c.LocalEndPoint.Port); // in the event that a port is listed twice, this will just return false on subsequent removals
                }
            }
            log.WriteEntry(string.Format("Port Scan: {0} are free", string.Join(",", AvailablePorts), EventLogEntryType.Information));
        }
    }

    // Be a Windows service
    public partial class TcpPortTrackerService : ServiceBase
    {
        ServiceHost host;

        public TcpPortTrackerService()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            TcpPortTracker.log = this.EventLog; // Make the Eventlog accessible by the TcpPortTracker

            // Listen on TCP port 8000
            host = new ServiceHost(typeof(TcpPortTracker));
            host.AddServiceEndpoint(typeof(ITcpPortTracker), new NetTcpBinding(SecurityMode.None), "net.tcp://0.0.0.0:8000");
            host.Open();
        }

        protected override void OnStop()
        {
            if (host != null)
            {
                host.Close();
            }
        }
    }
}
