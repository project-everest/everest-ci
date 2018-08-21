$app = $args[0]
$appargs = $args | Select-Object -Skip 1
if ($appargs.Count -eq 0) {
  Start-Process $app -Verb RunAs -Wait
} else {
  Start-Process $app -ArgumentList "$appargs" -Verb RunAs -Wait
}
