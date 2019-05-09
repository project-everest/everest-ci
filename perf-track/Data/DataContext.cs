//-----------------------------------------------------------------------
// <copyright file="DataContext.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack.Data
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.WindowsAzure.Storage;
    using Microsoft.WindowsAzure.Storage.Table;
    using PerfTrack.Models;

    /// <summary>
    /// The data context class.
    /// </summary>
    public class DataContext : DbContext
    {

        /// <summary>
        /// Creates a new instance of DataContext
        /// </summary>
        /// <param name="options">The options object.</param>
        public DataContext(DbContextOptions<DataContext> options) : base(options)
        {
        }

        public DbSet<Metric> Metrics { get; set; }
    }
}