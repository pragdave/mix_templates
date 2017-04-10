# Mix Template—a package for creating customized directory trees



Manage the local installation and uninstallation of templates used
by `mix gen`.

### Install

    $ mix archive.install hex mix_templates
    
You probably also need to install the generator:

    $ mix archive.install hex mix_generator
    


### Use

A high-level summary:

* `mix template`

  List the locally installed templates.

* `mix template.hex`

  List the templates available on hex.

* `mix template.install «source»`

  Install a template from source.

* `mix template.uninstall «name»`

  Uninstall the template with the given name.

The «source» can be

    path/
        the path to a local directory tree containing the template

    git https://path/to/git/repo
    git https://path/to/git/repo branch git_branch
    git https://path/to/git/repo tag git_tag
    git https://path/to/git/repo ref git_ref
        install from a git repository

    github user/project
    github user/project branch git_branch
    github user/project tag git_tag
    github user/project ref git_ref
        install from github from the given user and project

    hex hex_package
    hex hex_package 1.2.3
        install from a hex package. Use mix template.hex to find
        available packages.

Templates are installed in $MIX_HOME/templates (by default ~/.mix/templates).

### Seed

Details for each individual task can be found using `mix help template`,
`mix help tmplate.hex` and so on.

See `Mix.Tasks.Gen` (in project
[:mix_generator](https://github.com/pragdave/mix_generator)) for details 
of how to use these templates.


### License

Apache 2.0. See LICENSE.md for details.

### See also

For information on writing your own templates, see the moduledoc for MixTemplate,
also in this package.
