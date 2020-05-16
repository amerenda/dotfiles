#!/usr/bin/env bash

get_project_users () {
    local out=$(gcloud compute --project=${project} project-info describe --flatten="commonInstanceMetadata.items[2].value" | awk '{print $1 }' | awk -F '\\:' '{ print $1 }')
    if ! [[ ${out} == *"null"* ]]; then 
        printf "Project: ${project}"
        printf "\n"
        echo "${out}"
    fi
}


get_list_of_projects () {
    gcloud projects list | awk '{ print $1 }' | grep -v 'PROJECT_ID'
}

check_compute_api () {
    gcloud services list --project=${project} | grep 'compute.googleapis.com' >/dev/null
}


for project in $(get_list_of_projects); do
    if check_compute_api; then
        get_project_users ${project}
    fi
done

