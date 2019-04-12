//-----------------------------------------------------------------------
// <copyright file="DataManager.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack.Data
{
    using System;
    using System.Threading.Tasks;
    using Microsoft.WindowsAzure.Storage;
    using Microsoft.WindowsAzure.Storage.Table;
    using PerfTrack.Models;

    /// <summary>
    /// The data manager class.
    /// </summary>
    public class DataManager
    {
        /// <summary>
        /// The table object.
        /// </summary>
        private CloudTable table;

        /// <summary>
        /// Creates a new instance of DataManager
        /// </summary>
        /// <param name="connectionstring">The connectionstring value.</param>
        public DataManager(string connectionstring)
        {
            var storageAccount = CloudStorageAccount.Parse(connectionstring);

            // Create the table client.
            var tableClient = storageAccount.CreateCloudTableClient();

            // Create the CloudTable object that represents the "imageconversionjobs" table.
            this.table = tableClient.GetTableReference("PerfTrack");
            this.table.CreateIfNotExistsAsync().ConfigureAwait(false).GetAwaiter().GetResult();
        }

        /// <summary>
        /// Inserts the metric to the data store.
        /// </summary>
        /// <param name="metric">The metric object.</param>
        /// <returns>Returns the task object.</returns>
        public async Task TrackMetric(Metric metric)
        {
            var insertOperation = TableOperation.Insert(metric);
            TableResult result = await this.table.ExecuteAsync(insertOperation);
        }
    }
}