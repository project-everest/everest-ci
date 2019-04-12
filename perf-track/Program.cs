//-----------------------------------------------------------------------
// <copyright file="Program.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack
{
    using System;
    using System.IO;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Configuration;
    using PerfTrack.Data;
    using PerfTrack.Models;

    /// <summary>
    /// The Program class.
    /// </summary>
    public class Program
    {
        private const string MathPattern = @"\((.+)\)\tQuery-stats \((.+)\)\t(.+) statistics={(.+)}$";

        /// <summary>
        /// The main method entry point.
        /// </summary>
        /// <param name="args">The arguments array.</param>
        public static void Main(string[] args)
        {
            // Validate args
            if (args.Length != 4)
            {
                PrintCommandHelp();
                return;
            }

            // Validate Build Id
            if (!int.TryParse(args[0], out int buildId))
            {
                Console.WriteLine($"Error - Invalid build id: {args[0]}");
                return;
            }

            // Validate log path
            if (!File.Exists(args[3]))
            {
                Console.WriteLine($"Error - Unable to find log file: {args[2]}");
                return;
            }

            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);

            var configuration = builder.Build();
            var storageConnection = configuration.GetConnectionString("DefaultStorageConnection");

            // GenerateMetrics
            var projectName =  args[1];
            var branchName = args[2];
            var logPath = args[3];

            var regEx = new Regex(MathPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            var dataManager = new DataManager(storageConnection);

            using (var file = new System.IO.StreamReader(logPath))
            {
                string line;
                while ((line = file.ReadLine()) != null)
                {
                    // Find matches.
                    var matches = regEx.Matches(line);

                    if (matches.Count == 0)
                    {
                        continue;
                    }

                    // Retrieve all tokens
                    var sourceCode = matches[0].Groups[1].Value;
                    var queryName = matches[0].Groups[2].Value;
                    var status = matches[0].Groups[3].Value;
                    var statistics = matches[0].Groups[4].Value;

                    // Break statistics into separate metrics
                    var metrics = statistics.Split(" ");

                    // For each metric Track it.
                    foreach(var m in metrics)
                    {
                        // break metric name and metric value
                        var mInfo = m.Split("=");

                        var metric = new Metric()
                        {
                            MetricId = Guid.NewGuid().ToString(),
                            ProjectName = projectName,
                            BranchName = branchName,
                            BuildId = buildId,
                            QueryName = queryName,
                            MetricName =  mInfo[0],
                            MetricValue = double.Parse(mInfo[1]),
                            SourceCode = sourceCode,
                            Status = status

                        };

                        dataManager.TrackMetric(metric).ConfigureAwait(false).GetAwaiter().GetResult();
                    }
                }

                file.Close();
            }
        }

        /// <summary>
        /// Prints the command line help.
        /// </summary>
        private static void PrintCommandHelp()
        {
            Console.WriteLine(Environment.NewLine + "Usage: perf-track [build-id] [project-name] [branch-name] [log-path]");
        }
    }
}
