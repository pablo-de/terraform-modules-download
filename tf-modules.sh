#!/bin/bash

#Script to download the latest version of terraform modules from github.

#Variables.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
NOW=$(date +"%d-%m-%Y - %H:%M")

MODULES_DIR="$DIR/github"
MODULES_GITLAB="$DIR/gitlab"

#Array with the modules.
declare -a TF_MODULES=(
    tf-aws-lambda="https://github.com/terraform-aws-modules/terraform-aws-lambda"
    tf-aws-apigateway="https://github.com/terraform-aws-modules/terraform-aws-apigateway-v2"
    tf-aws-autoscaling="https://github.com/terraform-aws-modules/terraform-aws-autoscaling"
    tf-aws-ec2="https://github.com/terraform-aws-modules/terraform-aws-ec2-instance"
    tf-aws-ecr="https://github.com/terraform-aws-modules/terraform-aws-ecr"
    tf-aws-eks="https://github.com/terraform-aws-modules/terraform-aws-eks"
    tf-aws-elb="https://github.com/terraform-aws-modules/terraform-aws-elb"
    tf-aws-s3="https://github.com/terraform-aws-modules/terraform-aws-s3-bucket"
    tf-aws-security-group="https://github.com/terraform-aws-modules/terraform-aws-security-group"
    tf-aws-vpc="https://github.com/terraform-aws-modules/terraform-aws-vpc"
    tf-aws-rds="https://github.com/terraform-aws-modules/terraform-aws-rds"
    tf-aws-cloudfront="https://github.com/terraform-aws-modules/terraform-aws-cloudfront"
)

#Function to download the modules.
function tf_download_dir {

    #Check if the directory "$MODULES_DIR"/$1 exists or create it.
    if [ ! -d "$MODULES_DIR"/$1 ]; then
        mkdir -p "$MODULES_DIR"/$1
    fi

    cd "$MODULES_DIR"/$1 || exit

    #Check if remote upstream already exists and is already up to date.
    if [ ! -z "$(git remote -v | grep upstream)" ] && [ ! -z "$(git pull upstream master)" ]; then
        #Print no changes with date.
        echo "$NOW | No changes in $1 module"
    else
        #Check git init.
        if [ ! -d "$MODULES_DIR"/$1/.git ]; then
            git init
        fi

        git remote add upstream "$2"
        git pull upstream master
        git pull upstream master --allow-unrelated-histories
        git fetch --tags upstream

        #Get the latest tag and save into a variable tag.
        tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")

        #Write in TAG.md the last tag.
        echo "Version: $tag" >TAG.md

        # Check if the directory gitlab exists.
        if [ ! -d "$MODULES_GITLAB/$1" ]; then
            mkdir -p "$MODULES_GITLAB/$1"
        fi

        # Copy .tf and tag.md files to gitlab directory.
        cp -r "$MODULES_DIR"/"$1"/*.tf "$MODULES_GITLAB"/"$1"
        cp -r "$MODULES_DIR"/"$1"/TAG.md "$MODULES_GITLAB"/"$1"

        #Check if folder modules and templates exist.
        if [ -d "$MODULES_DIR"/"$1"/modules ]; then
            cp -r "$MODULES_DIR"/"$1"/modules "$MODULES_GITLAB"/"$1"
        fi
        if [ -d "$MODULES_DIR"/"$1"/templates ]; then
            cp -r "$MODULES_DIR"/"$1"/templates "$MODULES_GITLAB"/"$1"
        fi
        if [ -d "$MODULES_DIR"/"$1"/wrappers ]; then
            cp -r "$MODULES_DIR"/"$1"/wrappers "$MODULES_GITLAB"/"$1"
        fi

        #Print changes with date in format in log file.
        echo "$NOW | New module $1 = $tag" >>"$MODULES_GITLAB"/changes.log

        # cd "$MODULES_GITLAB" || exit

        # #Check if git is initialized.
        # if [ ! -d "$MODULES_GITLAB"/$1/.git ]; then
        #     git init
        # fi

        # #check if remote origin already exists.
        # if [ -z "$(git remote -v | grep origin)" ]; then
        #     git remote add origin
        # fi

        # git add "$MODULES_GITLAB"/$1
        # git add "$MODULES_GITLAB"/changes.log
        # git commit -m "Add module $1 = $tag"
        # git push origin main

        cd "$MODULES_DIR" || exit

    fi

}

#Download the modules.
for i in "${TF_MODULES[@]}"; do
    #Split the array.
    IFS='=' read -ra ADDR <<<"$i"
    #Call the function.
    tf_download_dir ${ADDR[0]} ${ADDR[1]}
done
