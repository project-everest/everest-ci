'use strict';

window.chartColors = {
	red: 'rgb(255, 99, 132)',
	orange: 'rgb(255, 159, 64)',
	yellow: 'rgb(255, 205, 86)',
	green: 'rgb(75, 192, 192)',
	blue: 'rgb(54, 162, 235)',
	purple: 'rgb(153, 102, 255)',
	grey: 'rgb(201, 203, 207)'
};

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
            array.push(new Array());
            array.push(new Array());
            array.push(new Array());

            $(obj).each(function(i, val) {
                var index = 0;
                if (val.PreviousMetricValue == val.MetricValue) {
                    index = 1;
                } else if (val.PreviousMetricValue > val.MetricValue) {
                    index = 2;
                }

                array[index].push({
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
                        label: 'worse',
                        borderColor: window.chartColors.red,
                        data: array[0]
                    },
                    {
                        label: 'equal',
                        borderColor: window.chartColors.blue,
                        data: array[1]
                    },
                    {
                        label: 'better',
                        borderColor: window.chartColors.green,
                        data: array[2]
                    }]
                },
                options: {
                    title: {
						display: true,
						text: 'rlimit-count'
					},
                    scales: {
                        xAxes: [{
                            type: 'linear',
                            position: 'bottom'
                        }]
                    },
                    plugins: {
                        zoom: {
                            // Container for pan options
                            pan: {
                                // Boolean to enable panning
                                enabled: true,

                                // Panning directions. Remove the appropriate direction to disable
                                // Eg. 'y' would only allow panning in the y direction
                                mode: 'xy',
                                rangeMin: {
                                    // Format of min pan range depends on scale type
                                    x: null,
                                    y: null
                                },
                                rangeMax: {
                                    // Format of max pan range depends on scale type
                                    x: null,
                                    y: null
                                },
                                // Function called once panning is completed
                                // Useful for dynamic data loading
                                onPan: function({chart}) { console.log(`I was panned!!!`); }
                            },
                            zoom: {
                                enabled: true,
                                drag: true,
                                mode: 'xy',
                                rangeMin: {
                                    // Format of min zoom range depends on scale type
                                    x: null,
                                    y: null
                                },
                                rangeMax: {
                                    // Format of max zoom range depends on scale type
                                    x: null,
                                    y: null
                                },
                                speed: 0.1
                            }
                        }
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

            window.myLine = myChart;
        }

        // Make page visible
        $('#pageLoading').hide();
        $('#pageContent').show();
    });
    request.fail(function (data) {
        $('#loading').text("Error. No performance data available.");
    });
}

$("#resetZoom").click(function() {
    window.myLine.resetZoom();
});

/// Runs once document is ready.
$(document).ready(function() {
    var buildId = getUrlVars()["buildid"];
    if (buildId === undefined) {
        $('#loading').text("Error. No build id");
        return;
    }

    downloadPerfData(buildId);
});