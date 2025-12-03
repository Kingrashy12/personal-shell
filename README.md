# Personal Shell

A simple, lightweight command-line shell written in Zig, providing essential shell functionality with a focus on minimalism and performance.

## Features

- **Builtin Commands**: Supports core shell commands including `cd`, `pwd`, `echo`, `type`, `exit`, and `clear`/`cls`
- **External Command Execution**: Seamlessly execute system commands and external programs
- **Output Redirection**: Redirect command output to files using `>` operator
- **REPL Interface**: Interactive read-eval-print loop with directory-aware prompt
- **Cross-Platform**: Built with Zig for portability across Windows, Linux, and macOS

## Installation

### Prerequisites

- [Zig](https://ziglang.org/) compiler (version 0.15.2 or later recommended)

### Build from Source

1. Clone the repository:

   ```bash
   git clone https://github.com/Kingrashy12/personal-shell
   cd personal-shell
   ```

2. Build the executable:

   ```bash
   zig build
   ```

3. (Optional) Install to system path:
   ```bash
   ./copy-to-bin.bash  # Copies to ~/bin/psl.exe on Windows
   ```

## Usage

Run the shell interactively:

```bash
zig build run
```

Or execute the built binary directly:

```bash
./zig-out/bin/psl
```

### Example Commands

```bash
$ pwd
/home/user

$ echo Hello, World!
Hello, World!

$ cd /tmp
$ pwd
/tmp

$ type zig
zig is /usr/local/bin/zig

$ ls -la > directory_listing.txt

$ exit
```

### Builtin Commands

- `cd <directory>` - Change current directory
- `pwd` - Print working directory
- `echo <text>` - Display text or variables
- `type <command>` - Display command type or location
- `exit` - Exit the shell
- `clear` / `cls` - Clear the terminal screen

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Reporting bugs
- Suggesting features
- Submitting pull requests
- Code style and testing

### Development Setup

1. Fork and clone the repository
2. Make your changes
3. Test with `zig build run`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainers

- **Raphael** - [GitHub](https://github.com/<username>)
