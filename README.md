# system-cue

Assorted [cue](https://cuelang.org/) packages maintained by @system

## Conventions

### Kubernetes objects organization
Kubernetes yaml objects are expected to live under the following prefixes:

* `"kube"`: known entry point to kubernetes configurations
* `strings.ToCamel(kind)`: grouping kinds together helps defining commong policies for them
* `metadata.name`: the identifier of the object

For example: `kube: service: loki: {}`  

Yaml exporters are expected to loop over `kube` and `kind` and produce a yaml object per `metadata.name`

### Converting cue to yaml
To mimic the kustomize workflow, all directories including cue files should provide a `build` command that exports all cue files into yaml. Additionally, this command should live in a file called `kube_tool.cue`, which will signal to external tools that the directory is relying on cue to produce some manifests.

### Kustomize compatibility
Kustomize and cue can coexist in a directory, but should not depend on each other. Directories that use both are expected to apply both outputs of `kustomize build .` and `cue build .`.

### Providing input for modules
When defining the `kube` object, include a top level `#input` structure with the variables you want to expose (example in `./alerts/main.cue`)

Then when importing the kube object in the client module, union the imported kube with a struct with the desired values:
```
kube: importedPackage.kube & { #input: {
  var1: "value 1"
  var2: "value 2"
}}
```

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
1. Initialize the cue module: `hof mod init cue ""`. Only modules can import cue files from other modules or directories, so we need to init even if we don't intend to export the module, so we can leave the module name empty.

2. Edit the `cue.mods` file and required the modules you want to import:
```
require (
  github.com/utilitywarehouse/system-cue v0.X.X
)
```
In theory v0.0.0 should pull "latest", not sure if tag or commit, but doesn't matter since it doesn't work at all.

3. Vendor the dependencies with `hof mod vendor cue`. This will create the cue.sums file. Note that this will recreate the `cue.mod/pkg` directory, deleting modules not managed by the hof tool. You probably want to add `cue.mod/pkg` to `.gitignore`.
