/// Gets the url variables
function getUrlVars() {
    var vars = [], hash;
    var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
        hash = hashes[i].split('=');
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
    }
    return vars;
}

function downloadPerfData(buildId) {
    var url = "https://everestlogstorage.blob.core.windows.net/perftrack/" + buildId + "-perftrack.txt";
    console.log( url );

    // Request data.
    var request = $.get(url);
    request.done(function (data) {
        if (data !== undefined && data !== null) {
            var obj = jQuery.parseJSON( data );
            var array = [];

            $(obj).each(function(i, val) {
                array.push({
                    index : i,
                    QueryName: val.QueryName,
                    MetricName: val.MetricName,
                    MetricValue: val.MetricValue,
                    PreviousMetricValue: val.PreviousMetricValue,
                    CurrentAverageMetricValue: val.CurrentAverageMetricValue,
                    x: val.PreviousMetricValue,
                    y: val.MetricValue
                });
            });

            var ctx = document.getElementById('myChart');
            var myChart = new Chart(ctx, {
                type: 'scatter',
                data: {
                    datasets: [{
                        label: 'rlimit-count',
                        data: array
                    }]
                },
                options: {
                    scales: {
                        xAxes: [{
                            type: 'linear',
                            position: 'bottom'
                        }]
                    },
                    tooltips: {
                        callbacks: {
                            label: function(tooltipItem, data) {
                                var item = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];

                                var label = "Query Name: (" + item.QueryName + ");" +
                                " Current: " + item.MetricValue + ";" +
                                " Previous: " + item.PreviousMetricValue + ";" +
                                " Average: " + item.CurrentAverageMetricValue;

                                return label;
                            }
                        }
                    }
                }
            });
        }

        // Make page visible
        $('#pageLoading').hide();
        $('#pageContent').show();
    });
    request.fail(function (data) {
        $('#loading').text("Error. No performance data available.");
    });
}

/// Runs once document is ready.
$(document).ready(function() {
    var buildId = getUrlVars()["buildid"];
    if (buildId === undefined) {
        $('#loading').text("Error. No build id");
        return;
    }

    downloadPerfData(buildId);
});