// This function is responsible to check the state of a container.
function checkContainerStatus() {
    var containerText = $('#containerText').text();
    if (containerText.indexOf('ContainerIP') != -1) {
        return;
    }

    $('#ContainerTable').show();

    var ipPos = containerText.indexOf('@');
    var ip = containerText.substring(ipPos + 1);
    var url = "http://" + ip;

    $.ajax({
        url: url,
        type: 'GET',
        crossDomain: true,
        dataType: 'jsonp',
        timeout: 30000,
        headers: { "Access-Control-Allow-Origin": "*" },
        complete: function (data) {
            if (data.readyState == '4' && data.status == '200') {

                // Container is running
                $('#containerStatus').text('Running');
                $('#containerStatus').css({ "font-weight" : "Bold" });
            }
            else {

                // Check if container was already destroyed.
                var dateTime = $('#buildDataTime').text();
                var startTime = moment.utc(dateTime, 'MM/DD/YYYY HH:mm:ss');
                var currentTime = moment.utc();

                var duration = moment.duration(currentTime.diff(startTime));
                var hours = duration.asHours();
                if (hours >= 12) {
                    $('#containerStatus').text('Destroyed!');
                    return;
                }

                // Still deploying
                $('#containerStatus').text('Deploying...');
                setTimeout(checkContainerStatus(), 300000);
            }
        }
    });
}

// On Document ready
$(document).ready(function () {

    var offendersText = $('#offendersText').text();
    if (offendersText.indexOf('$Offenders') === -1) {
        $('#Offenders').show();
    }

    // $('#containerText').text('ssh everest@104.42.41.81');
    // $('#buildDataTime').text('10/24/2018 07:50:28');
    setTimeout(checkContainerStatus(), 1000);
});
