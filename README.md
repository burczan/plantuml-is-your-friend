# PlantUML-is-your-friend

- [PlantUML-is-your-friend](#plantuml-is-your-friend)
  - [How to...](#how-to)
    - [... run `example` project](#-run-example-project)
    - [... create new diagram project](#-create-new-diagram-project)
    - [... switch between projects](#-switch-between-projects)
  - [FAQ](#faq)
    - [Which elements are supported in `element_generator.iuml`?](#which-elements-are-supported-in-element_generatoriuml)

## How to...

### ... run `example` project

1. Set `PROJECT_DIR` variable value in `.env` file to `example` (the default value).
1. Run `npm run project:regenerate_all` (this will generate all the files related to the diagram).

This diagram is taken from [PlantUML - Entity Relationship Diagram](https://plantuml.com/ie-diagram).

### ... create new diagram project

1. Set `PROJECT_DIR` variable value in `.env` file to the new project name (for example `my_new_project`).
1. Run `npm run create_new_project`.

### ... switch between projects

1. Set `PROJECT_DIR` variable value in `.env` file to match the project folder name.

## FAQ

### Which elements are supported in `element_generator.iuml`?

For complete list of elements' types, see [Class Diagram --> Declaring element](https://plantuml.com/class-diagram).
