# Contributing
## Prepare environment for development
0. Install pixi package manager

    Follow instructions from: <https://prefix.dev/docs/pixi/overview#installation>
    You can also install it on ArchLinux by using `yay pixi`. With nix `pixi`
    package is also available on **unstable** channel.

1. Activate virtual environment: `pixi shell`.

    > I also recommend installing `direnv` and running `direnv allow .envrc`:
    > it will automagically activate environment once you open the directory of
    > the Project and deactivate it once you leave it.

2. Install dependencies: `pixi install`.

Now you're ready to go! You have just installed all dependencies
for project and development.

Now all subfolders of `src/` are installed as local dev packages for easier management.

As for development tooling you have now:
- [flake8](https://flake8.pycqa.org/en/latest/) for linting (`pixi run lint-check`)
- [black](https://pypi.org/project/black/) for code formatting (`pixi run format-check` or to
    also fix if possible: `pixi run format`)
- [isort](https://pypi.org/project/isort/) for sorting imports (`pixi run order-imports-check` or
    to fix if possible: `pixi run order-imports`)
- [mypy](https://www.mypy-lang.org) for static type checking (`pixi run types-check`)
- [pytest](https://docs.pytest.org/en/8.0.x/) for testing (you can use `pixi run test` to run all tests)
- [pre-commit](https://pre-commit.com/) for running all these tools on commit
  (you can use `pixi run pre-commit-check` to check)

## Prepare code editor for development
### Neovim
Install [none-ls](https://github.com/nvimtools/none-ls.nvim) - it will hook up
all installed tools in your environment. Run `:NullLsInfo` in neovim to check
status.

### VSCode
Install related extension for each tool:
- [extension for flake8](https://marketplace.visualstudio.com/items?itemName=ms-python.flake8)
- [extension for black](https://marketplace.visualstudio.com/items?itemName=ms-python.black-formatter)
- [extension for isort](https://marketplace.visualstudio.com/items?itemName=ms-python.isort)
- [extension for mypy](https://marketplace.visualstudio.com/items?itemName=ms-python.mypy-type-checker)

Don't forget to change required settings in your VSCode `settings` file.
For example:
```json
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": "explicit"
    },
  },
  "isort.args":["--profile", "black"],
```

Don't fiddle with detailed settings of instruments: they're already configured
locally in project. Change only editor-related options.

## Create new package
To create new package:
1. Create new directory in `src/<my_package_name>`
2. Add empty `__init__.py` and empty `py.typed`
3. Add your package <my_package_name> to 'packages' list in `setup.cfg`

Now you can write code in your new package and use it in other modules by
importing it via `from <my_package_name>.<file> import <function>`! You can
also do import it that way in tests.

## Testing
Run `rixi run test` - it will run pytest for all files in `tests/` directory with
options set in `pytest.ini`.

## Running in Docker
You can also use Docker to run everything in containerized environment without
installing anything.

First of all, you have to set Docker related variables in `.env`, see
`.env.example` - you can pick any name you wish. After that you can use `make` commands for
common development workflow:
1. Build image: `make build-image`
2. Start container: `make start`
3. Run any of the checks (commands have similar names to `pixi run ...`
   commands):
    - `make lint-check`
    - `make format-check`
    - `make order-imports-check`
    - `make types-check`

4. Connect to image if you want: `make connect`
5. And finally, stop once finished working: `make stop`

> On Windows you should install `make` or just use commands from `Makefile`
> manually

## Making Changes to CI/CD Pipeline
Use kebab-style for naming stages and jobs as it's common style in `pixi`
tasks and `make` targets.
