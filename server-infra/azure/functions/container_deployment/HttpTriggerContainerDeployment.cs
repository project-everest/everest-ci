using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ContainerInstance.Fluent;
using Microsoft.Azure.Management.ContainerInstance.Fluent.Models;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Authentication;
using Microsoft.Azure.Management.Storage;
using Microsoft.Azure.Management.Storage.Fluent;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Microsoft.Msr.Everest
{
    public static class HttpTriggerContainerDeployment
    {
        // The Azure connection object.
        private static IAzure _azure = null;

        // Gets the Azure connection object.
        private static IAzure AzureConn
        {
            get
            {
                // If object is null, create it.
                if (_azure == null)
                {
                    // Read application settings.
                    var clientId = GetEnvironmentVariable("Azure_AppId");
                    var clientSecret = GetEnvironmentVariable("Azure_AppIdPassword");
                    var tenantId = GetEnvironmentVariable("Azure_TenantId");

                    // Create object.
                    var credential = SdkContext.AzureCredentialsFactory.FromServicePrincipal(clientId, clientSecret, tenantId, AzureEnvironment.AzureGlobalCloud);
                    _azure = Microsoft.Azure.Management.Fluent.Azure
                        .Configure()
                        .WithLogLevel(Azure.Management.ResourceManager.Fluent.Core.HttpLoggingDelegatingHandler.Level.Basic)
                        .Authenticate(credential)
                        .WithDefaultSubscription();
                }

                return _azure;
            }
        }

        // Request Container to de deployed and update log file
        [FunctionName("HttpTriggerContainerDeployment")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("HttpTriggerContainerDeployment HTTP trigger function processed a request.");

            // Validate calls are comming from expected source.
            string urlReferrer = req.Headers["Referer"] + "";
            if (string.IsNullOrWhiteSpace(urlReferrer) || !urlReferrer.StartsWith("https://everestlogstorage.blob.core.windows.net/", StringComparison.OrdinalIgnoreCase))
            {
                return new ForbidResult();
            }

            // Download log
            string logFile = null;
            using (var wc = new System.Net.WebClient())
            {
                var content = await wc.DownloadDataTaskAsync(urlReferrer);
                logFile = System.Text.Encoding.Default.GetString(content);
            }

            // If unable to download content, report error.
            if (string.IsNullOrWhiteSpace(logFile))
            {
                return new NoContentResult();
            }

            // Find Image name and container name
            var match = Regex.Match(logFile, "ImageName=\"(.*)\" ContainerName=\"(.*)\"", RegexOptions.IgnoreCase);
            if (!match.Success || match.Groups.Count < 3)
            {
                return new NoContentResult();
            }

            var imageName = match.Groups[1].Captures[0].Value;
            var containerName = match.Groups[2].Captures[0].Value;

            // Read application settings
            string resourceGroupName = GetEnvironmentVariable("Azure_ResourceGroupName");
            string containerGroupName = GetEnvironmentVariable("Azure_ContainerGroupName");
            string containerRegistryName = GetEnvironmentVariable("Azure_ContainerRegistryName");
            string containerRegistryPassword = GetEnvironmentVariable("Azure_ContainerRegistryPassword");
            string storageAccount = GetEnvironmentVariable("Azure_StorageAccount");
            string storageAccessKey = GetEnvironmentVariable("Azure_StorageAccessKey");

            // Connect to Azure and validate
            var resourceGroup = await AzureConn.ResourceGroups.GetByNameAsync(resourceGroupName);

            // Create the container group
            var containerGroupDefinition = AzureConn.ContainerGroups.Define(containerName)
                .WithRegion("westus")
                .WithExistingResourceGroup(resourceGroupName);

            var containerOSDefinition = containerGroupDefinition.WithLinux();
            if (containerName.Contains("windows", StringComparison.OrdinalIgnoreCase))
            {
                containerOSDefinition = containerGroupDefinition.WithWindows();
            }

            var containerInstanceDefinition = containerOSDefinition
                .WithPublicImageRegistryOnly()
                .WithPrivateImageRegistry("everestvstsacr.azurecr.io", containerRegistryName, containerRegistryPassword)
                .WithoutVolume()
                .DefineContainerInstance(containerName)
                .WithImage(imageName)
                .WithExternalTcpPorts(22, 80, 443)
                .WithCpuCoreCount(4)
                .WithMemorySizeInGB(8)
                .Attach();

            // Request deployment
            var containerGroup = await containerInstanceDefinition.CreateAsync();

            // Update log summary with container ip.
            logFile = logFile.Replace("{ContainerIP}", containerGroup.IPAddress);

            // Make container info visible
            logFile = logFile.Replace("<div id=\"ContainerTable\" class=\"containerSummaryRow\" style=\"display:none;\">", "<div id=\"ContainerTable\" class=\"containerSummaryRow\">");

            // Hide deployment table
            logFile = logFile.Replace("id=\"DeploymentTable\" ", "id=\"DeploymentTable\" style=\"display:none;\"> ");

            // Update deployment datetime
            logFile = logFile.Replace("{DeploymentDateTime}", DateTime.UtcNow.ToString("MM/dd/yyyy HH:mm:ss"));

            // Get blob storage container (index 0) name and file name (index 1)
            var names = urlReferrer.Replace("https://everestlogstorage.blob.core.windows.net/", string.Empty).Split('/');

            // Upload new log file to azure blob
            string storageConnectionString = $"DefaultEndpointsProtocol=https;AccountName={storageAccount};AccountKey={storageAccessKey};EndpointSuffix=core.windows.net";
            CloudStorageAccount cloudStorageAccount = CloudStorageAccount.Parse(storageConnectionString);
            CloudBlobClient cloudBlobClient = cloudStorageAccount.CreateCloudBlobClient();
            CloudBlobContainer cloudBlobContainer = cloudBlobClient.GetContainerReference(names[0]);
            CloudBlockBlob blob = cloudBlobContainer.GetBlockBlobReference(names[1]);
            blob.Properties.ContentType = "text/html";
            await blob.UploadTextAsync(logFile);

            return new OkResult();
        }

        // Gets Application settings.
        private static string GetEnvironmentVariable(string name)
        {
            return System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }
    }
}
