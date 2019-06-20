# Continuous Integration for Project Everest

## Build definitions and triggers

- We use [an instance](https://msr-project-everest.visualstudio.com/Everest/) of Azure DevOps (formerly known as VSTS) for CI.
- We have Linux and Windows [build definitions](https://msr-project-everest.visualstudio.com/Everest/_build?definitionId=1).
- Linux builds trigger automatically on every commit to every branch **not** starting with an underscore of the Everest, FStar, KreMLin, hacl-star, mitls-fstar, Vale, and QuackyDucky repositories.
- We schedule daily Linux builds for all the above projects and have some scheduled builds for specific tasks: Everest automatic upgrades (daily), FStar binaries (weekly, Windows and Linux), FStar docs (weekly).
- Builds can be triggered from Azure DevOps by clicking on the "Queue" button in the build definition. Using this method, one can specify the branch and commit hash to use as well as an alternative Slack channel to receive a notification when the build finishes.
 
## Workflow

- The build logic of every project under CI is in the `.docker/build` folder in the top directory
- Every build is based on [this template](https://msr-project-everest.visualstudio.com/Everest/_taskgroup/0576cfad-6efe-47a5-b530-2646fb3cc914).
- Every project has a `config.json` file that sets variables used in the build definition. Importantly, it specifies a Docker base image (e.g. `"BaseContainerImageName" : "everest-ci"`) to start the build from and the branch and commit hash to use (`"BaseContainerImageTagOrCommitId": "latest"`, `"BranchName" : "master"`). `BaseContainerImageTagOrCommitId` can be either a commit hash or the special value `latest`, indicating the latest commit in the branch.
- These values should be changed only in very rare exceptions in main branches. If you would like to test a feature that requires a different commit or branch, then create a private branch and update `config.json` accordingly.
- A build starts by checking out from GitHub the branch and commit hash specified in the Azure DevOps queue dialog, or whichever commit triggered the build. It then uses the variables in the config file to either pull the specified base image from [Docker Hub](https://hub.docker.com/u/projecteverest) if it exists, or trigger a separate build and wait for it to finish if the base image has not been built yet.

## FStar binary and documentation builds

- FStar binary and documentation builds use `config-binaries.json` and `config-docs.json` instead of `config.json`.
- These builds use as base image a regular build of FStar.
- `config-binaries.json` used to specify `"BaseContainerImageTagOrCommitId": "latest"`, `"BranchName" : "master"` to use a build of the latest commit to FStar@master as base image. To avoid confusions and as an exception to the normal workflow, these variables are now *commented out* and FStar binaries and documentation builds use the Azure DevOps variables to get the base image branch and commit hash.
- Binaries and documentation builds from the latest commit to FStar@master continue to work as usual.
- Binaries and documentation builds from other branches or from previous commits to `master` will use the same branch and commit hash as base image.
- To use a different base image, remove the leading `_` from `_BaseContainerImageTagOrCommitId` and `_BranchName` in `config-{binaries,docs}.json` and modify their values accordingly.

## Debugging build failures

- Build notifications in Slack have a link to the build summary (click on the result, i.e. Sucess/Failure ...). These summaries have a link to the raw log (only the docker build phase). `wget`/`curl` the log and `grep` it locally at leisure, or quickly search in it from a browser (but beware logs can be huge).
- Build summaries also have a link to deploy the Docker container on Azure and make it available via SSH (`Click here to deploy Container`). This can be either arbitrarily long. The text of the link will update with the IP of the deployed container (e.g. `ssh everest@13.83.2.169`). To login you'll need to have added your public SSH key [here](https://github.com/project-everest/everest-ci/blob/master/server-infra/keys/authorized_keys) *before* the build happened.
- We upload images to [Docker Hub](https://hub.docker.com/u/projecteverest) at the end of the build process. If you have Docker installed, you can pull the image and run a container. The repository names in Docker Hub are self-descriptive, the tags are the commit hash (as specified in the VSTS build that uploaded the image). E.g.
```
$ docker pull projecteverest/fstar-binaries-linux:8c80e4840ab6
$ docker run --rm -it projecteverest/fstar-binaries-linux:8c80e4840ab6 /bin/bash
```
- Alternatively, projects have a `build_local.sh` script in the top folder that will replicate the build workflow locally (requires Docker). This is largely untested, but do try to fix or report any issues you experience.
- Build notifications in Slack also have a link to the VSTS build log (click on the duration). Infrastructure errors and other errors that don't show in the docker build phase can be debugged using the logs here.
- Finally, if you need help debugging a tricky issue, ask @s-zanella, @tahina-pro, @nikswamy, @protz, @wintersteiger (or @gugavaro) who are familiar with the workflow and will be happy to help.

## Issues and feature requests

If you want to file an issue or a feature request about CI please do it [here](https://msr-project-everest.visualstudio.com/Everest/_workitems/).

## In-depth technical information

More technical details about the CI process are available in [this wiki](https://github.com/mitls/mitls-papers/wiki#ci-system).
