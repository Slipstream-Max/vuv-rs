# vuv-rs

A Rust implementation of UV virtual environment manager. This tool provides a convenient way to manage Python virtual environments using [uv](https://github.com/astral-sh/uv).

## Prerequisites

- Rust toolchain (cargo)
- uv package manager
- Linux or macOS (Windows support through WSL)

## Installation

1. Clone this repository
2. Run the installation script:
```bash
./install.sh
```

## Usage

### Create a new virtual environment
```bash
vuv create -n myenv -p python3.11
```

### List all virtual environments
```bash
vuv list
```

### Activate a virtual environment
```bash
vuv activate myenv
```

### Install packages
```bash
vuv install package1 package2
```

### Uninstall packages
```bash
vuv uninstall package1 package2
```

### Remove a virtual environment
```bash
vuv remove -n myenv
```

### Configure default index
```bash
vuv config --default-index https://pypi.org/simple
```

## Features

- Fast and efficient virtual environment management
- Direct environment activation with `vuv activate`
- Support for multiple Python versions
- Package installation and uninstallation using uv
- Configuration management
- Cross-platform support (Linux, macOS, WSL)

## Directory Structure

- Virtual environments are stored in `~/.venvs`
- Configuration files are stored in `~/.vuv`
- The binary is installed in `~/.local/bin`

## Contributing

Feel free to open issues or submit pull requests for any improvements or bug fixes.

## License

MIT License 