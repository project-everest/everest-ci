# Continuous Integration for Project Everest

The main source of CI for Project Everest is a machine that runs behind the
corporate network, dubbed `everest-ci`. It is powerful (72-cores), and is
connected to VSTS, a private, invitation-only, proprietary CI system.

One can log onto the machine if connected to the Microsoft Corporate Network,
via rdesktop (user: everbld, password: ask Jonathan or Sreekanth), or using Mark
Russinovitch's excellent psexec.

[Build Logs](https://github.com/project-everest/ci-logs)

The logs are pushed to a public repository to make them easily accessible to
everyone. The CI machine uses GitHub SSH-key authentication to push build logs
as the user "dzomo". A dzomo is a hybrid betweek a yak and domestic cattle, and
is used to carry workloads for Everest expeditions.

Here's a quick overview of the current implemented CI jobs:
- **miTLS / CI**
  [!mitls-ci build status](https://msresearch-ext.visualstudio.com/_apis/public/build/definitions/83f09286-c288-4766-89cd-d267b6d93772/12/badge)
  run on every commit, run verification and build the FFI

Planning to have the following soon:
- **F\* / CI**: run on every commit, doesn't include expensive verification like crypto.
- **F\* / nightly**: verify all the things, including crypto and everything in
  examples/
- **everest / CI**: check that the given revisions of all projects lead to a
  successful build & run of mitls.exe
- **everest / upgrade**: check that the latest revisions of all projects lead to a
  successful build & run of mitls.exe
- **everest / nightly**: check that the install script, when run from an empty
  Ubuntu Docker container, leads to a successful build & run of mitls.exe

Read [ci](ci) for more information.
