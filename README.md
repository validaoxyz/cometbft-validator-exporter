# cometbft-validator-exporter
A script to export cometbft validator data for inclusion with prometheus-exporter

## how to run
Install the script, and use the `validator_stats.service` systemd unit template and fill out with your relevant validator data.

Finally, run `prometheus-exporter` with the flag ` --collector.textfile.directory=/tmp/node_exporter_custom_metrics` to include validator stats in the prometheus exporter data.