#!/bin/bash
#Prepare everest-ci and everest-logs repositories
cd $MYHOME
git clone git@github.com:/project-everest/everest-ci
git clone git@github.com:/project-everest/ci-logs
git config --global user.email "everbld@microsoft.com"
git config --global user.name "Dzomo the everest Yak"
