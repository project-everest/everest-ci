// Used to verify if deploying is running, we check 3 times to confirm.
count = 0;

// This function is responsible to check the state of a container.
function checkContainerStatus() {

    var containerText = $('#containerText').text();
    var ipPos = containerText.indexOf('@');
    var ip = containerText.substring(ipPos + 1);
    var url = "https://" + ip;

    var start = new Date().getTime(); //gets time of start
    var timeout = 10000;
    $.ajax({
        url: url,
        type: 'GET',
        cache: false,
        global: false,
        timeout: timeout,
        dataType: 'jsonp',
    }).always(function(data, textStatus, errorThrown) {
            var msec = new Date().getTime() - start; // duration
            if (textStatus == "timeout" || msec >= timeout / 2) {
                // Check if container was already destroyed.
                var dateTime = $('#deploymentDataTime').text();
                if (dateTime) {
                    var startTime = moment.utc(dateTime, 'MM/DD/YYYY HH:mm:ss');
                    var currentTime = moment.utc();

                    var duration = moment.duration(currentTime.diff(startTime));
                    var hours = duration.asHours();
                    if (hours >= 12) {
                        $('#containerStatus').text('Destroyed!');
                        return;
                    }
                }

                // Still deploying
                $('#containerStatus').text('Deploying...');
                setTimeout(checkContainerStatus(), 300000);

                count = 0;
            } else {
                if (++count == 3) {
                    // Container is running
                    $('#containerStatus').text('Running');
                    $('#containerStatus').css({ "font-weight" : "Bold" });
                } else {
                    setTimeout(checkContainerStatus(), 10000);
                }
            }
        });
}

// This function is responsible to deploy container.
function deployContainer() {

    var dateTime = $('#buildDataTime').text();
    if (dateTime) {
        var startTime = moment.utc(dateTime, 'MM/DD/YYYY HH:mm:ss');
        var currentTime = moment.utc();

        var duration = moment.duration(currentTime.diff(startTime));
        var hours = duration.asHours();
        if (hours >= 12) {
            $('#deployContainerText').text('Cannot deploy container from build older than 12 hours.');
            return;
        }
    }

    $('#deployContainerLink').hide();
    $('#deployContainerPanel').show();

    var url = "https://everestdeploycontainer.azurewebsites.net/api/HttpTriggerContainerDeployment?code=MsgeHNEPwpJ7DAn2qH3NBYecW5lZ0EfqHaS2vWNsCxDnNjlZN3Nasg==";

    $.ajax({
        url: url,
        type: 'POST',
        crossDomain: true,
        success: function(data, textStatus, xhr) {
            location.reload();
        },
        error: function(xhr, textStatus, message) {
            $('#deployContainerPanel').text('Error. Try again later!');
            $('#deployContainerPanel').fadeOut(5000, function(){
                $('#deployContainerLink').show();
                $('#deployContainerPanel').hide();
                $('#deployContainerPanel').text('Requesting deployment...');
            });
        }
    });
}

// On Document ready
$(document).ready(function () {

    $('body').on('click', '#deployContainerText', function() {
        deployContainer();
    });

    var offendersText = $('#offendersText').text();
    if (offendersText.indexOf('Offenders') === -1) {
        $('#Offenders').show();
    }

    var containerText = $('#containerText').text();
    if (containerText.indexOf('ContainerIP') != -1) {
        return;
    }

    $('#ContainerTable').show();
    checkContainerStatus();
});
