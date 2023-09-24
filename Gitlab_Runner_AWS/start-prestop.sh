#!/bin/bash

set -e						
#By using set -e, the script will stop execution if any subsequent command fails, allowing you to catch errors early and prevent further execution in potentially erroneous conditions.

if [ -z "$GITLAB_URL" ]; then
  echo 1>&2 "error: missing GITLAB_URL environment variable"
  exit 1
fi

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo 1>&2 "error: missing REGISTRATION_TOKEN environment variable"
  exit 1
fi

if [ -z "$RUNNER_DESCRIPTION" ]; then
  echo 1>&2 "error: missing RUNNER_DESCRIPTION environment variable"
  exit 1
fi

if [ -z "$RUNNER_TAGS" ]; then
  echo 1>&2 "error: missing RUNNER_TAGS environment variable"
  exit 1
fi

if [ -z "$RUNNER_EXECUTOR" ]; then
  echo 1>&2 "error: missing RUNNER_EXECUTOR environment variable"
  exit 1
fi

gitlab_url_without_https=$(echo "$GITLAB_URL" | sed 's/^https:\/\///')
echo $gitlab_url_without_https

# Download certs to gitlab runner directory
mkdir -p /etc/gitlab-runner/certs
openssl s_client -showcerts -connect $gitlab_url_without_https:443 -servername $gitlab_url_without_https < /dev/null 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/, /-----END CERTIFICATE-----/' > /etc/gitlab-runner/certs/$gitlab_url_without_https.crt

#Deregistering the existing runner
cleanup() {
	echo "SIGQUIT received, executing pre-stop commands..."
	#Deregister the existing runner
	#runner_token=$(grep -a4 "name" /etc/gitlab-runner/config.toml | awk -f'"' '/token/ {print $2}')
	runner_token=$(grep -A4 "name =" /etc/gitlab-runner/config.toml | awk -F'"' '/token/ {print $2}')
	for r_token in $runner_token; do
		gitlab-runner unregister --url $GITLAB_URL --token $r_token
	done
	#Verify and delete runner configurations
	gitlab-runner verify --delete
}

# Register runner
echo "registering gitlab runner"
if [[ "$RUNNER_EXECUTOR" == "shell" ]]; then
gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$REGISTRATION_TOKEN" \
  --tls-ca-file /etc/gitlab-runner/certs/$gitlab_url_without_https.crt \
  --executor shell \
  --description "$RUNNER_DESCRIPTION" \
  --tag-list "$RUNNER_TAGS" \
  --run-untagged="false" \
  --locked="true" \
  --access-level="not_protected"

elif [[ "$RUNNER_EXECUTOR" == "docker" ]]; then
gitlab-runner register \
  --non-interactive \
  --url "$GITLAB_URL" \
  --registration-token "$REGISTRATION_TOKEN" \
  --tls-ca-file /etc/gitlab-runner/certs/$gitlab_url_without_https.crt \
  --executor docker \
  --docker-image alpine:latest \
  --description "$RUNNER_DESCRIPTION" \
  --tag-list "$RUNNER_TAGS" \
  --run-untagged="false" \
  --locked="true" \
  --access-level="not_protected" \
  --docker-privileged \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock

else
  echo "Invalid executor type. Please provide 'shell' or 'docker'."
  exit 1
fi

#trapping the docker signals 
trap 'cleanup; exit 0' QUIT

#Keep the container running
#tail -f /dev/null
gitlab-runner run "$@" & wait $!



##########################


