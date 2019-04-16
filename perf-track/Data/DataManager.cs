//-----------------------------------------------------------------------
// <copyright file="DataManager.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack.Data
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
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
            if (string.IsNullOrWhiteSpace(connectionstring))
            {
                throw new ArgumentNullException("connectionstring");
            }

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
        public async Task TrackMetric(List<Metric> metrics)
        {
            var batchOperation = new TableBatchOperation();
            foreach (var m in metrics)
            {
                batchOperation.Insert(m);
            }

            if (batchOperation.Count > 0)
            {
                await this.table.ExecuteBatchAsync(batchOperation);
            }

        }

        /// <summary>
        /// Gets the previous Metric value for the given metric.
        /// </summary>
        /// <param name="projectName">The project name.</param>
        /// <param name="platform">The platform</param>
        /// <param name="queryName">The Query name.</param>
        /// <param name="metricName">The metric name.</param>
        /// <returns>Returns the metric value.</returns>
        public async Task<Tuple<double, double>> GetPreviousMetricValue(string projectName, string platform, string queryName, string metricName)
        {
            var query1 = TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.Equal, projectName);
            var query2 = TableQuery.GenerateFilterCondition("BranchName", QueryComparisons.Equal, "master");
            var query3 = TableQuery.GenerateFilterCondition("Platform", QueryComparisons.Equal, platform);
            var query4 = TableQuery.GenerateFilterCondition("QueryName", QueryComparisons.Equal, queryName);
            var query5 = TableQuery.GenerateFilterCondition("MetricName", QueryComparisons.Equal, metricName);
            var filter = TableQuery.CombineFilters(query1, TableOperators.And, query2);
            filter = TableQuery.CombineFilters(filter, TableOperators.And, query3);
            filter = TableQuery.CombineFilters(filter, TableOperators.And, query4);
            filter = TableQuery.CombineFilters(filter, TableOperators.And, query5);
            var query = new TableQuery<Metric>().Where(filter);

            TableContinuationToken token = null;
            var resultSegment = await this.table.ExecuteQuerySegmentedAsync(query, token);
            var results = resultSegment.Results;

            // If Metric did not exit before, we return 0
            if (results.Count == 0)
            {
                return new Tuple<double, double>(0, 0);
            }

            // If we have more than 10 items, we should remove extra items.
            if (results.Count > 10)
            {
                var batchOperation = new TableBatchOperation();
                for(var i = 10; i < results.Count; i++)
                {
                    batchOperation.Add(TableOperation.Delete(results[i]));
                }

                table.ExecuteBatchAsync(batchOperation).ConfigureAwait(false).GetAwaiter().GetResult();;
            }

            var currentValue =results[0].MetricValue;

            // Calculate average.
            var metricValues = results[0].MetricValue;
            var count = Math.Min(results.Count, 10);
            for(var i = 1; i < count; i++)
            {
                metricValues += results[i].MetricValue;
            }

            var average = metricValues / count;

            return new Tuple<double, double>(currentValue, average);
        }
    }
}