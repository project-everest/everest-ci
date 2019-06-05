//-----------------------------------------------------------------------
// <copyright file="Program.cs", company="Microsoft">
//     Copyright (c) Microsoft Corp. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace PerfTrack
{
    using System.Collections.Concurrent;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Reflection;
    using System.Text.RegularExpressions;
    using System.Text;
    using System.Threading.Tasks;
    using System;
    using Microsoft.EntityFrameworkCore;
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

        private static readonly object sync = new Object();

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
        /// arg[6] -> output file
        /// </param>
        public static void Main(string[] args)
        {
            // Validate args
            if (args.Length != 7)
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

            Console.WriteLine($"args:\n{args[0]}\n{args[1]}\n{args[2]}\n{args[3]}\n{args[4]}\n{args[5]}\n{args[6]}");

            // GenerateMetrics
            var projectName = args[1];
            var branchName = args[2];
            var platform = args[3];
            var collectMetrics = args[4].Split(" ");

            var regEx = new Regex(MathPattern, RegexOptions.Compiled | RegexOptions.IgnoreCase);

            using (var context = new DbContextFactory().CreateDbContext())
            {
                var dateTime = DateTime.UtcNow;

                // we always compare against master
                var filter = $"{projectName}-{platform}-master";
                var rows = context.Metrics.Where(m => m.ProjectName == filter).ToList();

                using (var file = new System.IO.StreamReader(logPath))
                {
                    var resultMetrics = new List<Metric>();

                    string line = null;
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

                            var metricName = mInfo[0];
                            var succeeded = status.StartsWith("succeeded", StringComparison.OrdinalIgnoreCase);
                            if (!succeeded)
                            {
                                continue;
                            }

                            var previousData = GetPreviousMetricValue(rows, metricName, queryName, succeeded);
                            var metric = new Metric()
                            {
                                ProjectName = $"{projectName}-{platform}-{branchName}",
                                BuildId = buildId,
                                QueryName = queryName,
                                MetricName = metricName,
                                MetricValue = double.Parse(mInfo[1]),
                                PreviousMetricValue = previousData.Item1,
                                CurrentAverageMetricValue = previousData.Item2,
                                SourceCode = sourceCode,
                                Status = status,
                                Succeeded = succeeded,
                                RowDateTime = dateTime,
                            };

                            resultMetrics.Add(metric);
                            if (branchName == "master")
                            {
                                context.Metrics.Add(metric);
                            }
                        }
                    }

                    // We only persist master branch metrics.
                    if (branchName == "master" && resultMetrics.Count > 0)
                    {
                        // Remove old records
                        var rowsToDelete = context.Metrics.Where(m => m.RowDateTime < DateTime.UtcNow.AddDays(-30)).ToList();
                        if (rowsToDelete.Any())
                        {
                            context.Metrics.RemoveRange(rowsToDelete);
                        }

                        context.SaveChanges();
                    }

                    file.Close();

                    var json = JsonConvert.SerializeObject(resultMetrics);
                    using (var fs = File.Create(args[6]))
                    {
                        // Add some text to file
                        Byte[] title = new UTF8Encoding(true).GetBytes(json);
                        fs.Write(title, 0, title.Length);
                    }
                }
            }
        }

        /// <summary>
        /// Gets the previous Metric value for the given metric.
        /// </summary>
        /// <param name="projectName">The project name.</param>
        /// <param name="platform">The platform</param>
        /// <param name="metricName">The metric name.</param>
        /// <param name="queryName">The Query name.</param>
        /// <returns>Returns the metric value.</returns>
        public static Tuple<double, double> GetPreviousMetricValue(List<Metric> rows, string metricName, string queryName, bool succeeded)
        {
            var results = rows.Where(r => r.MetricName == metricName && r.QueryName == queryName && r.Succeeded == succeeded).OrderByDescending(m => m.BuildId).ToList();

            // If Metric did not exit before, we return 0
            if (!results.Any())
            {
                return new Tuple<double, double>(0, 0);
            }

            var currentValue = results[0].MetricValue;

            // Calculate average.
            var metricValues = results[0].MetricValue;
            for (var i = 1; i < results.Count; i++)
            {
                metricValues += results[i].MetricValue;
            }

            var average = metricValues / results.Count;

            return new Tuple<double, double>(currentValue, average);
        }
    }
}