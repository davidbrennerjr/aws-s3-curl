#!/bin/bash

################################################################################  
# Copyright 2016-2017 by David Brenner Jr <david.brenner.jr@gmail.com>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
# Usage
# ./aws_s3_curl.sh NameOfS3Bucket AccessKeyID SecretKey /path/to/file
#
# Required Options
#
# NameOfS3Bucket
# Specify the name your S3 bucket. For example to upload a new file to your
# website www.example.com then the name of the bucket is www.example.com
#
# AccessKeyID
# Specify the Access Key ID of the user and the group you created in IAM that
# allows uploading new files to your S3 bucket.
#
# SecretKey
# Specify the Secret Key that associated with the Access Key ID. You may have to
# create a new Access Key ID to see its Secret Key.  
#
# /path/to/file
# Specify the absolute path to a single file to be uploaded to your S3 bucket.
################################################################################

# check number of arguments
function check_args() {
  if [ "$BASH_ARGC" != "4" ]; then
    echo -e "FAILURE: Script has missing/invalid options\n"
    echo -e "Usage: # ./aws_s3_curl.sh NameOfS3Bucket AccessKeyID SecretKey /path/to/file\n"
    exit 1
  fi
}
check_args || exit 1

# required tools must be installed. run test immediately.
function check_dependencies() {
  # required packages/tools 
  tools='coreutils curl openssl util-linux debianutils lsb-release'
  # required installation status
  status='install ok installed'
  # check dpkg then other packages/tools
  if [ -x /usr/bin/dpkg ]; then
    for name in $tools; do
      # get package status
      package="$(dpkg-query -W --showformat='${Package} ${Status} ${Version}\n' $name | cut -d ' ' -f 1,2,3,4)"
      if [ "$package" != "$(echo $name $status)" ]; then
        echo "FAILURE: Script requires installation of $name"
        exit 1
      fi
    done
  else
    echo "FAILURE: Script requires installation of dpkg to check dependencies"
    exit 1
  fi     
}
check_dependencies || exit 1

# check distribution. run test immediately.
function check_distribution() {
  tested_os='Ubuntu 16'
  # required package to get system info
  package="$(dpkg-query -W --showformat='${Package} ${Status} ${Version}\n' lsb-release | cut -d ' ' -f 1,2,3,4)"
  if [ "$package" != "lsb-release install ok installed" ]; then
    echo -e "WARNING: Can't get OS name/version info using lsb-release"
  else
    # get OS name
    name="$(lsb_release -a 2>/dev/null | head -n 1 | tr ':\t' ' ' | cut -d ' ' -f 4)";
    # get OS version
    version="$(lsb_release -a 2>/dev/null | head -n 3 | tail -n 1 | tr ':\t' ' ' | cut -d ' ' -f 3 | cut -d '.' -f 1)"
    # check host
    if [ "$name $version" != "$tested_os" ]; then
      echo "WARNING: Distribution not supported $name $version"
      echo "Supported distributions: $tested_os"  
    fi
  fi
}
check_distribution

# send a put request to amazon's api gateway with resource permissions to upload
# a file to the s3 bucket. 
DATE=$(date -R)
BUCKET="$1"
FILE="$4"
COMMAND="PUT\n\napplication/octet-stream\n$DATE\n/$BUCKET/$FILE"
ACCESSID="$2"
SECRETKEY="$3"
ENCODED=$(echo -en $COMMAND | openssl sha1 -hmac $SECRETKEY -binary | base64)
curl -X PUT -T "$FILE" -H "Host: $BUCKET.s3.amazonaws.com" -H "Date: $DATE" -H "Content-Type: application/octet-stream" -H "Authorization: AWS $ACCESSID:$ENCODED" http://$BUCKET.s3.amazonaws.com/$FILE

# cleanup
unset DATE
unset BUCKET
unset FILE
unset COMMAND
unset ACCESSID
unset SECRETKEY
unset ENCODED

exit 0

