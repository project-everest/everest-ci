# Continuous Integration for Project Everest

The main source of CI for Project Everest is a machine that runs behind the
corporate network, dubbed `everest-ci`. It is powerful (72-cores), and is
connected to Azure DevOps, a private, invitation-only, proprietary CI system.

One can log onto the machine if connected to the Microsoft Corporate Network,
via rdesktop (user: everbld, password: ask Jonathan or Sreekanth), or using Mark
Russinovitch's excellent psexec.

One can skip CI by putting `***NO_CI***` in the commit message.

One can connect to the Azure DevOps web interface via https://msr-project-everest.visualstudio.com/Everest -- if you don't have access, that's an issue, ask us to get access.

## Build summary:
-  **Everest-CI-Windows** - Check that the designated revisions of all projects (in hashes.sh) lead to a successful build & run of mitls.exe 
- **Everest-Nightly Upgrade-Windows** - Check that the latest revisions of all projects lead to a successful build & run of mitls.exe; record it as a new set of revisions 
- **Everest-Nightly-Windows** - Generate a docker image in which we build, verify and extract all the projects, then upload it to the Docker Hub if successful. 
- **Hacl\*-CI-Windows** – Extract the hacl-star code to C using KreMLin, and check that it compiles and runs; lax-check the hacl-star code against the constant-time restricted integer modules; verify the hacl-star code. 
- **FStar-CI-Windows** - Run on every push, doesn't include expensive verification like crypto. Note – this runs on every branch, not just changes to master. 
- **FStar-Nightly-Linux** - Verify all the things, including crypto and everything in examples/ -- also regenerate the hints, the ocaml snapshot, and push to repo 
- **FStar-Docs Nightly-Linux** –  Parse the special documentation comments and generate a series of markdown files that document the modules in fstar/ulib; then, translate them to HTML and upload them to fstarlang.github.io 
- **miTLS-CI-Windows** - Run on every commit, run verification and build the FFI 
- **miTLS-Nightly-Windows** - Run verification, build the FFI and regenerate the hints. 
- **VALE-CI-Linux** - Build on every push, but only builds Vale. It does NOT do verification. 
- **VALE-x64 CI-Windows** - Build on every push, but only builds Vale. It does NOT do verification. 
- **VALE-x86 CI-Windows** - Build and verify every check in for VALE. Build is x86 but verification is x86, x64 and ARM. This is the main verification run as X64 and Linux just build VALE and NOT do any verification

Read [ci](ci) for more information on how the CI was implemented.

For up to date build results, details, logs and history, go to the [Project Everest Dashboard](http://everestdashboard.azurewebsites.net/). 

The logs are also pushed to a public [repository](https://github.com/project-everest/ci-logs). The CI machine uses GitHub SSH-key authentication to push build logs as the user "dzomo". A dzomo is a hybrid betweek a yak and domestic cattle, and is used to carry workloads for Everest expeditions.

## Usage

See `./everest-ci help`.

## Adding new targets

The script takes as an argument the exact action to be performed (e.g.
`fstar-nightly`). Adding a new action is often as simple as adding a new
argument, and creating a corresponding build definition on the VSTS side of
things.

## Contributing

We welcome pull requests to this script, using the usual fork project + pull
request GitHub model. For members of Everest, Jonathan Protzenko has the keys
to the everest project on GitHub and can grant write permissions on this
repository so that you can develop your feature in a branch directly. Jonathan
watches pull requests and will provide timely feedback unless he's on vacations
or in another timezone.
