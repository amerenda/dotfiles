#!/usr/bin/env bash
JENKINS_URL="https://deploy.2pth.com"
jobs_to_display=(data-common-PR platform-PR data-common-avro-fields tracking-api-pr-pipeline	platform-azkaban-deploy-PROD platform data-common tracking-api-prod-deploy-pipeline	tracking-api-preprod-deploy-pipeline pixel_PR_build_pipeline RTAPI-Build-Deploy-Pipeline)

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

for job in $(curl --user amerenda:$JENKINS_TOKEN -sg "$JENKINS_URL/api/json?tree=jobs[name,url]" | jq '.jobs[].name' -r);
do
    if containsElement "$job" "${jobs_to_display[@]}"; then
        echo "Job Name : $job"
        echo -e "Build Number\tTimestamp"
        for build in $(curl --user amerenda:$JENKINS_TOKEN -sg "$JENKINS_URL/job/$job/api/json?tree=allBuilds[number]" | jq '.allBuilds[].number' -r);
        do
            curl --user amerenda:$JENKINS_TOKEN -sg "$JENKINS_URL/job/$job/$build/api/json" | jq '(.number|tostring) + "\t\t" + (.timestamp|tostring)' -r
        done
        echo "================"
    fi
done
