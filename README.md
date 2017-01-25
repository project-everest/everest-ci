# Continuous Integration for Project Everest

The main source of CI for Project Everest is a machine that runs behind the
corporate network, dubbed `everest-ci`. It is powerful (72-cores), and is
connected to VSTS, a private, invitation-only, proprietary CI system.

One can log onto the machine if connected to the Microsoft Corporate Network,
via rdesktop (user: everbld, password: ask Jonathan or Sreekanth), or using Mark
Russinovitch's excellent psexec.

The machine shares the folder `C:\Users\everbld\Agents\Linux2` with the Docker
Ubuntu instance (mounted as `/LinuxAgent`). One can skip CI by putting
`***NO_CI***` in the commit message.

[GO TO BUILD LOGS](https://github.com/project-everest/ci-logs)

The logs are pushed to a public repository to make them easily accessible to
everyone. The CI machine uses GitHub SSH-key authentication to push build logs
as the user "dzomo". A dzomo is a hybrid betweek a yak and domestic cattle, and
is used to carry workloads for Everest expeditions.

Here's a quick overview of the current implemented CI jobs:
- **miTLS / CI** (Windows)
  ![mitls-ci build status](https://msresearch-ext.visualstudio.com/_apis/public/build/definitions/83f09286-c288-4766-89cd-d267b6d93772/12/badge)
  run on every commit, run verification
- **F\* / CI** (Windows)
  ![fstar-ci build status](https://msresearch-ext.visualstudio.com/_apis/public/build/definitions/83f09286-c288-4766-89cd-d267b6d93772/27/badge)
  run on every commit, doesn't include expensive verification like crypto.
- **F\* / nightly** (Ubuntu / Docker)
  ![fstar-nightly build status](https://msresearch-ext.visualstudio.com/_apis/public/build/definitions/83f09286-c288-4766-89cd-d267b6d93772/22/badge)
  verify all the things, including crypto and everything in
  examples/ -- also regenerate the hints + OCaml snapshot and push!
- **everest / CI**: check that the designated revisions of all projects (in
  `hashes.sh`) lead to a successful build & run of mitls.exe
- **everest / upgrade**: check that the latest revisions of all projects lead to a
  successful build & run of mitls.exe; record it as a new set of revisions
- **everest / nightly**: check that the install script, when run from an empty
  Ubuntu Docker container, leads to a successful build & run of mitls.exe

Read [ci](ci) for more information.

## Usage

See `./everest-ci help`.

## Adding new targets

The script takes as an argument the exact action to be performed (e.g.
`fstar-nightly`). Adding a new action is often as simple as adding a new
argument, and creating a corresponding build definition on the VSTS side of
things.

## Contributing

We welcome pull requests to this script, using the usual fork project + pull
request GitHub model. For members of Everest, Sreekanth Kannepali has the keys
to the everest project on GitHub and can grant write permissions on this
repository so that you can develop your feature in a branch directly. Jonathan
watches pull requests and will provide timely feedback unless he's on vacations
or in another timezone.
