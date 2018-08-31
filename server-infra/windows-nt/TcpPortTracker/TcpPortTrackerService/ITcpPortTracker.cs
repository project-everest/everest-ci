using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ServiceModel;

namespace TcpPortTrackerService
{
    [ServiceContract(Namespace="http://Everest.ServiceModel.TcpPortTracker")]
    interface ITcpPortTracker
    {
        // Return an available TCP port on the machine
        [OperationContract]
        int GetAvailablePort();

        // Return a TCP port to the pool
        [OperationContract]
        void FreePort(int Port);
    }
}
