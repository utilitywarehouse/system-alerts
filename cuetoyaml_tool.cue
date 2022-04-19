package kube

import (
	"encoding/yaml"
	"tool/cli"
)

command: build: {
	task: print: cli.Print & {
		text: yaml.MarshalStream(objects)
	}
}

objects: [ for kind in kube for object in kind {object}]
