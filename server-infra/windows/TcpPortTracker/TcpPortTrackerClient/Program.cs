using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceModel;
using System.Text;
using System.Threading.Tasks;
using TcpPortTrackerService;

//
// WCF client app, for finding an available TCP port number.  The process exit code is
// either -1 for error, or the TCP port number.
//
// The machine name should point to a server that is running the TcpPortTrackerService
// and Docker.
//

namespace TcpPortTrackerClient
{
    class Program
    {
        static void Usage()
        {
            Console.WriteLine("Usage:");
            Console.WriteLine("  TcpPortTrackerClient get servername           - returns a TCP port as the process exit code");
            Console.WriteLine("  TcpPortTrackerClient free servername portnum  - frees a TCP port");
            Environment.Exit(-1);
        }

        // Connect to the remote WCF server
        static ITcpPortTracker Connect(string servername)
        {
            var cf = new ChannelFactory<ITcpPortTracker>(new NetTcpBinding(SecurityMode.None), string.Format("net.tcp://{0}:8000", servername));
            return cf.CreateChannel();
        }

        static void Main(string[] args)
        {
            if (args.Length < 2)
            {
                Usage();
            }
            if (args[0] == "get") // allocate a new TCP port number
            {
                if (args.Length != 2)
                {
                    Usage();
                }
                var s = Connect(args[1]);
                try
                {
                    int AvailablePort = s.GetAvailablePort();
                    Console.WriteLine("Got available port {0} from {1}", AvailablePort, args[1]);
                    Environment.Exit(AvailablePort);
                }
                catch (System.ServiceModel.EndpointNotFoundException)
                {
                    Console.WriteLine("Unable to connect to the server.  The server may be down.");
                    Environment.Exit(-1);
                }
            }
            else if (args[0] == "free") // release a TCP port number
            {
                if (args.Length != 3)
                {
                    Usage();
                }
                var s = Connect(args[1]);
                try {
                    int Port = Int32.Parse(args[2]);
                    s.FreePort(Port);
                    Console.WriteLine("Freed port {0} on {1}", Port, args[1]);
                }
                catch (System.ServiceModel.EndpointNotFoundException)
                {
                    Console.WriteLine("Unable to connect to the server.  The server may be down.");
                    Environment.Exit(-1);
                }
            }
            else
            {
                Usage();
            }
        }
    }
}
