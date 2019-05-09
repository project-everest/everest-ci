//-----------------------------------------------------------------------
// <copyright file="Metric.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack.Models
{
    using System;
    using System.ComponentModel.DataAnnotations;
    using System.ComponentModel.DataAnnotations.Schema;
    using Microsoft.WindowsAzure.Storage.Table;

    /// <summary>
    /// The Metric class.
    /// </summary>
    public class Metric
    {
        /// <summary>
        /// Gets or sets the Row Id.
        /// </summary>
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        /// <summary>
        /// Gets or sets the Build Id.
        /// </summary>
        public int  BuildId { get; set; }

        /// <summary>
        /// Gets or sets the Project Name.
        /// </summary>
        public string  ProjectName { get; set; }

        /// <summary>
        /// Gets or sets the Source code.
        /// </summary>
        public string  SourceCode { get; set; }

        /// <summary>
        /// Gets or sets the Status.
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// Gets or sets whether it succeeded.
        /// </summary>
        public bool Succeeded { get; set; }

        /// <summary>
        /// Gets or sets the Query name.
        /// </summary>
        public string QueryName { get; set; }

        /// <summary>
        /// Gets or sets the Metric name.
        /// </summary>
        public string MetricName { get; set; }

        /// <summary>
        /// Gets or sets the metric value.
        /// </summary>
        public double MetricValue { get; set; }

        /// <summary>
        /// Gets or sets the Previous metric value.
        /// </summary>
        public double PreviousMetricValue { get; set; }

        /// <summary>
        /// Gets or sets the current average metric value.
        /// </summary>
        public double CurrentAverageMetricValue { get; set; }

                /// <summary>
        /// Gets or sets the row date time.
        /// </summary>
        public DateTime RowDateTime { get; set; }
    }
}