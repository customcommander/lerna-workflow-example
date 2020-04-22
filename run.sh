#!/bin/sh

docker run -it --rm --mount type=bind,src=$PWD,dst=/workspaces/run -w /workspaces/run customcommander/lerna-workflow-example sh workflow.sh
