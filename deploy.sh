gsutil -m cp -r docs/index.html gs://lr.tagimg.net
gsutil -m cp -r docs/installation.html gs://lr.tagimg.net
gsutil web set -m index.html -e 404.html gs://lr.tagimg.net
