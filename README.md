# system-cue

Assorted [cue](https://cuelang.org/) packages maintained by @system

## Conventions and recommendations

### Kubernetes objects organization
Kubernetes yaml objects are expected to live under the following prefixes:

* `"kube"`: known entry point to kubernetes configurations
* `strings.ToCamel(kind)`: grouping kinds together helps defining commong policies for them
* `metadata.name`: the identifier of the object

For example: `kube: service: loki: {}`  

Yaml exporters are expected to loop over `kube` and `kind` and produce a yaml object per `metadata.name`

### Converting cue to yaml
To mimic the kustomize workflow, all directories including cue files should provide a `build` command that exports all cue files into yaml. `./cuetoyaml_tool.cue` is an example cue tool that will convert kube objects with the format we explained above into yaml manifests.

### Kustomize compatibility
Kustomize and cue can coexist in a directory, but should not depend on each other. Directories that use both are expected to apply both outputs of `kustomize build .` and `cue build .`.

### Providing input for packages
We recommend 2 kinds of input in packages, living in the top level

`#env`: "environmental variables" to use across the package
`#data`: actual values needed to construct the output objects:
  * Data should be exposed in an easy to access way, which means using maps instead of lists, so values can be modified easily by the package consumers. Fields that can be modified should be defined as defaults instead of "hard" values, so consumers can override them.
  * The structure of #data does not need to match the output objects, and it should not include any inferable or generic values.

When importing a package, just union(&) it with the input and with any #data modifications:

```
import "example.io/module/packageName"

_env: {var1: "value1"}

_packageName: packageName & {#env: _env}

_packageName: #data: someField: "newValue"

...(do something with _packageName)
```

Good examples of #env and #data can be found in `./alert/group/...`

### Allowing deletions
In CUE, it is not possible to remove or delete a field that has been set.

To simulate that funcionality, it's necessary to play with CUE's list comprehensions and conditionals. Instead of defining the fields directly, they can be build with a for loop with a condition to include the field. By modifying that related value, we can effectively delete a field from the output

An example can be found in `./alert/`, where a `_disable` field in `./alert/env.cue` is used to determine if a rule should be included in the exported config map generated in `./alert/main.cue`

### Naming conventions
In theory, "definitions" (#identifiers) are CUE's way of signaling schemas, but since they are so useful for other purposes (like exposing data for input), it's recommended to append `Schema` to definitions that are intended to be used for validation, and are not providing values.

If using #data to hold the important values we humans care about, it's also a good idea to include `Data` in the schemas that are validating input data

Example:
`#AlertSchema`: is a schema for how exported alert fields should look like, to be consumed by some 3rd party (prometheus in our case)
`#AlertDataSchema`: is a schema for how alert values should be given to a module

### Reusing a package with different configurations
If a package is intended to be used as a base, for example by different teams, it can be imported with different identifiers, and then instantiated with different #env values.

For that, we need to use CUE's custom imports:

```
import (
	team1base "github.com/utilitywarehouse/path/to/base:basePackageName"
	team2base "github.com/utilitywarehouse/path/to/base:basePackageName"
)

_team1env: {var1: "value1"}
_team2env: {var1: "value2"}

_team1base: team1base & {#env: _team1env}
_team2base: team2base & {#env: _team2env}

...
```

### Recommended file organization
* `main.cue`: entry point of the package, should have the exported fields
* `schemas.cue`: definitions for schemas, both for #data and for exported objects, used to provide validation
* `env.cue`: #env definition
* `data.cue`: #data definition
* `*-data.cue`: values for #data

## Working with modules
CUE has the concept of modules and packages (https://cuelang.org/docs/concepts/packages/), but currently modules can only be imported from `cue.mod/pkg/` and there is no native mechanism to import or vendor code from external sources. There's also a lack of mechanism to define dependencies.

The proposal to add the missing mechanisms lives at https://github.com/cue-lang/cue/issues/851. Until the proposal is implemented, the recommended workaround is to use https://github.com/hofstadter-io/hof, that provides the most basic parts of dependency management.

This section includes the basic for working with cue modules using hof

### How to create a module so it can be imported
1. Initialize the cue module: `hof mod init cue github.com/utilitywarehouse/repo-name`. Modules are defined by a `cue.mod` dir, and to simplify the bootstratping process until the tooling is more mature, we recommend to make a single module at the root of repositories.

2. Produce the cue packages and commit them. When creating packages remember that:
  * packages are defined by the `package` clause, not by their path
  * when importing a package from a path, it will import all files from that package on that directoriy AND all parent directories until module root

3. Tag the commit you want to export with a semver format and push the tags. Note that versions carry the same backward compatibility contract as go version, so it's probably a good idea to stick with v0.x.x until we have a better grasp on cue and it's ecosystem. The hof vendoring tool is not great with updating versions so it's recommended to develop locally, but a possible convention would be using minor versions for stable releases and patch versions for development releases. Tags are needed because sadly `hof` cannot target commits as references.

### Using an external module
1. Initialize the cue module: `hof mod init cue "github.com/utilitywarehouse/kubernetes-manifests/path/to/dir"`. Only modules can import cue files from other modules or directories, so we need to init even if we don't intend to export the module. The module name doesn't matter, but we can as well use the correct one.

2. Edit the `cue.mods` file and required the modules you want to import:
```
require (
  github.com/utilitywarehouse/system-cue v0.X.X
)
```
In theory v0.0.0 should pull "latest", not sure if tag or commit, but doesn't matter since it doesn't work at all.

3. Vendor the dependencies with `hof mod vendor cue`. This will create the cue.sums file. Note that this will recreate the `cue.mod/pkg` directory, deleting modules not managed by the hof tool. You probably want to add `cue.mod/pkg` to `.gitignore`.

### Local development
Until CUE gets a native depency management system, it can be annoying to work with remote modules locally. Our recommendation is to locally symlink the external module inside `cue.mod/pkg` to ease with local development, and properly test the hof integration before releasing the new module version.
