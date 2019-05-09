using System.Diagnostics;
using System.IO;
using System.Reflection;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Configuration.FileExtensions;
using Microsoft.Extensions.Configuration.Json;

namespace PerfTrack.Data
{
    public class DbContextFactory : IDesignTimeDbContextFactory<DataContext>
    {
        private static string connectionString;

        public DataContext CreateDbContext()
        {
            return CreateDbContext(null);
        }

        public DataContext CreateDbContext(string[] args)
        {
            if (string.IsNullOrEmpty(connectionString))
            {
                connectionString = LoadConnectionString();
            }

            Debug.Assert(!string.IsNullOrEmpty(connectionString), "Invalid connection string");
            var builder = new DbContextOptionsBuilder<DataContext>();
            builder.UseSqlServer(connectionString);

            return new DataContext(builder.Options);
        }

        private static string LoadConnectionString()
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(Path.GetDirectoryName(Assembly.GetEntryAssembly().Location)) // Comment this line to run EF migrations.
                .AddJsonFile("appsettings.json", optional: false);

            var configuration = builder.Build();

            return configuration.GetConnectionString("SqlConnection");
        }
    }
}