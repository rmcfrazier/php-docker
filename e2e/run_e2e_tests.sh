#!/bin/sh
# Copyright 2015 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ev

if [ -z "${GOOGLE_APPLICATION_CREDENTIALS}"  ]; then
    # This must be a pull request from other repository.
    # Skipping all of the following.
    echo "Skipping e2e test"
    exit 0
fi

# Dump the credentials from the environment variable.
php dump_credentials.php

# Use the service account for gcloud operations.
gcloud auth activate-service-account --key-file ${GOOGLE_APPLICATION_CREDENTIALS}

# Upload the local image to gcr.io with a tag `testing`.
docker tag php-nginx gcr.io/${GOOGLE_PROJECT_ID}/php-nginx:testing
gcloud docker push gcr.io/${GOOGLE_PROJECT_ID}/php-nginx:testing

# Run e2e tests
vendor/bin/phpunit -c e2e.xml

# If all succeeds and if it is a push to the master, upload the image.
if [ "${TRAVIS_PULL_REQUEST}" = "false" ] && [ "${TRAVIS_BRANCH}" = "master" ]
then
    docker tag php-nginx gcr.io/${GOOGLE_PROJECT_ID}/php-nginx:latest
    gcloud docker push gcr.io/${GOOGLE_PROJECT_ID}/php-nginx:latest
fi
