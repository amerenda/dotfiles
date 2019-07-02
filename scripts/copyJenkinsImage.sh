#!/usr/bin/env bash

PROD_JENKINS_AGENT_IMAGE='jenkins-docker-agent-latest'

#JENKINS_GCP_PROJECT='impact-devops-prod'
JENKINS_GCP_PROJECT='nomadic-bison-143517'

SOURCE_PROJECT='fq-platform'

echo "getting most recent jenkins docker agent image..."
MOST_RECENT_JENKINS_DOCKER_AGENT_IMAGE=$(gcloud compute images list --project fq-platform --filter="name:jenkins-docker-" --sort-by=createTime | tail -n1 | awk '{ print $1 }')

echo "most recent jenkins docker agent image: ${MOST_RECENT_JENKINS_DOCKER_AGENT_IMAGE}"

echo "deleting old image from ${JENKINS_GCP_PROJECT}"
gcloud compute images delete "${PROD_JENKINS_AGENT_IMAGE}" --project "${JENKINS_GCP_PROJECT}" --quiet


echo "copying ${MOST_RECENT_JENKINS_DOCKER_AGENT_IMAGE} from ${SOURCE_PROJECT} to ${JENKINS_GCP_PROJECT}"
gcloud compute --project="${JENKINS_GCP_PROJECT}" images create "${PROD_JENKINS_AGENT_IMAGE}" --source-image="${MOST_RECENT_JENKINS_DOCKER_AGENT_IMAGE}" --source-image-project="${SOURCE_PROJECT}" --quiet
