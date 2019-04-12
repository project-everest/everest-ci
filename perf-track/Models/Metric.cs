//-----------------------------------------------------------------------
// <copyright file="Metric.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack.Models
{
    using System;
    using Microsoft.WindowsAzure.Storage.Table;

    /// <summary>
    /// The Metric class.
    /// </summary>
    public class Metric : TableEntity
    {
        /// <summary>
        /// Gets or sets the Metric Id.
        /// </summary>
        [IgnoreProperty]
        public string MetricId
        {
            get
            {
                return this.RowKey;
            }

            set
            {
                this.RowKey = value;
            }
        }

        /// <summary>
        /// Gets or sets the Project name.
        /// </summary>
        [IgnoreProperty]
        public string ProjectName
        {
            get
            {
                return this.PartitionKey;
            }

            set
            {
                this.PartitionKey = value;
            }
        }

        /// <summary>
        /// Gets or sets the Branch name.
        /// </summary>
        public string BranchName { get; set; }

        /// <summary>
        /// Gets or sets the Build id.
        /// </summary>
        public int BuildId { get; set; }

        /// <summary>
        /// Gets or sets the Source code.
        /// </summary>
        public string  SourceCode { get; set; }

        /// <summary>
        /// Gets or sets the Status.
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// Gets or sets the Query name.
        /// </summary>
        public string QueryName { get; set; }

        /// <summary>
        /// Gets or sets the Metric name.
        /// </summary>
        /// <value></value>
        public string MetricName { get; set; }

        /// <summary>
        /// Gets or sets the metric value.
        /// </summary>
        public double MetricValue { get; set; }
    }
}