//-----------------------------------------------------------------------
// <copyright file="Program.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Reflection;
    using System.Text;
    using System.Text.RegularExpressions;
    using System.Threading.Tasks;
    using Microsoft.Extensions.Configuration;
    using Newtonsoft.Json;
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
        /// <param name="args">
        /// The arguments array.
        /// arg[0] -> Build Id
        /// arg[1] -> Project name
        /// arg[2] -> Branch name
        /// arg[3] -> Platform
        /// arg[4] -> Metrics to be collected
        /// arg[5] -> Log Path
        /// </param>
        public static void Main(string[] args)
        {
            // Validate args
            if (args.Length != 6)
            {
                Console.WriteLine(Environment.NewLine + "Usage: perf-track [build-id] [project-name] [branch-name] [log-path]");
                return;
            }

            // Validate Build Id
            if (!int.TryParse(args[0], out int buildId))
            {
                Console.WriteLine($"Error - Invalid build id: {args[0]}");
                return;
            }

            // Validate log path
            var logPath = args[5];
            if (!File.Exists(logPath))
            {
                Console.WriteLine($"Error - Unable to find log file: {logPath}");
                return;
            }

            var builder = new ConfigurationBuilder()
                .SetBasePath(Path.GetDirectoryName(Assembly.GetEntryAssembly().Location))
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);

            var configuration = builder.Build();
            var storageConnection = configuration.GetConnectionString("DefaultStorageConnection");

            // GenerateMetrics
            var projectName = args[1];
            var branchName = args[2];
            var platform = args[3];
            var collectMetrics = args[4].Split(" ");

            var regEx = new Regex(MathPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);
            var dataManager = new DataManager(storageConnection);

            using (var file = new System.IO.StreamReader(logPath))
            {
                var batchMetrics = new List<Metric>();
                var resultMetrics = new List<Metric>();

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
                    foreach (var m in metrics)
                    {
                        // break metric name and metric value
                        var mInfo = m.Split("=");

                        // If metric is not marked to be collect ignore it.
                        if (!collectMetrics.Contains(mInfo[0]))
                        {
                            continue;
                        }

                        var previousData = dataManager.GetPreviousMetricValue(projectName, platform, queryName, mInfo[0]).GetAwaiter().GetResult();
                        var metric = new Metric()
                        {
                            MetricId = Guid.NewGuid().ToString(),
                            ProjectName = projectName,
                            BranchName = branchName,
                            Platform = platform,
                            BuildId = buildId,
                            QueryName = queryName,
                            MetricName = mInfo[0],
                            MetricValue = double.Parse(mInfo[1]),
                            PreviousMetricValue = previousData.Item1,
                            CurrentAverageMetricValue = previousData.Item2,
                            SourceCode = sourceCode,
                            Status = status
                        };

                        batchMetrics.Add(metric);

                        // We upload every 1000 items
                        // We only persist master branch metrics.
                        if (branchName == "master" && batchMetrics.Count == 100)
                        {
                            if (batchMetrics.Count > 0)
                            {
                                dataManager.TrackMetric(batchMetrics).ConfigureAwait(false).GetAwaiter().GetResult();
                            }

                            resultMetrics.AddRange(batchMetrics);
                            batchMetrics.Clear();
                        }
                    }
                }

                // We only persist master branch metrics.
                if (branchName == "master")
                {
                    if (batchMetrics.Count > 0)
                    {
                        dataManager.TrackMetric(batchMetrics).ConfigureAwait(false).GetAwaiter().GetResult();
                    }

                    resultMetrics.AddRange(batchMetrics);
                    batchMetrics.Clear();
                }

                file.Close();

                var json = JsonConvert.SerializeObject(resultMetrics);
                using (var fs = File.Create("perftrack.txt"))
                {
                    // Add some text to file
                    Byte[] title = new UTF8Encoding(true).GetBytes(json);
                    fs.Write(title, 0, title.Length);
                }
            }
        }
    }
}
