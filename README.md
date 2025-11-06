# RRR.jl: Remote REPL Runner

RRR.jl (Remote REPL Runner) is a powerful Julia-based server and Fish shell
client designed to improve interactive programming workflow.
 It allows you to manage multiple REPL sessions (Julia, Python, or any custom
 command) as persistent background processes, and interact with them seamlessly
 from your editor or terminal.
It's true it may not be of great use for viewing your makie plots
in you ide or terminal, but if you forgot if it was `max` or 
`maximum`, then sure a quick trial via a persistent repl from your editor
could help.

## Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Helix Editor Integration](#helix-editor-integration)

## Features

- **LightWeight**: Julia is known for it's slow startup time, but the rrr server
  is light enough to start in a few seconds.
- **Unified REPL Management:** Run and control multiple Julia, Python, or custom REPL sessions from a single interface.
- **Persistent Sessions:** REPLs run in the background, maintaining their state across commands.
- **Efficient Communication:** Utilizes Unix Domain Sockets for high-performance inter-process communication.
- **Simple Client:** A lightweight Fish shell script (`rrr`) provides all necessary commands.

## How It Works

RRR.jl operates on a client-server architecture:

1.  **RRR Server (Julia):** A Julia server process (`RRR.jl`) runs in the background, listening on a Unix Domain Socket (usually `/tmp/rrr.sock`). This server manages a collection of child REPL processes (Julia, Python, etc.).
2.  **REPL Processes:** When you create a session (e.g., a Python REPL), the server launches it as a subprocess. Communication with these child REPLs uses a not-so-robust *sentinel-based protocol* to reliably send commands and capture their full output (including multi-line results and error tracebacks).
3.  **RRR Client (Fish):** The `rrr` Fish shell script acts as your interface. It connects to the RRR server via the Unix socket, sends your commands (e.g., create a session, run code, kill a session), and displays the server's responses.

## Installation

### Prerequisites

Before installing RRR.jl, ensure you have the following installed:

-   **Julia:** The Julia programming language (version 1.6 or newer recommended).
-   **Fish Shell:** The friendly interactive shell.
-   **`netcat` (nc):** A networking utility, used for socket communication.
-   **`uuidgen`:** A utility for generating UUIDs (usually part of `util-linux` on Linux).

### Steps

1.  **Navigate to the RRR.jl directory:**
    ```bash
    cd /path/to/RRR.jl
    ```
2.  **Run the install script:**
    This will create a symlink to the `rrr` client script in `~/.local/bin` and set up the Julia project environment.
    ```bash
    ./rrr install
    ```
3.  **Add `~/.local/bin` to your PATH:**
    If you haven't already, ensure `~/.local/bin` is in your shell's `PATH` environment variable so you can run `rrr` from anywhere. For Fish shell, add this to your `~/.config/fish/config.fish`:
    ```fish
    fish_add_path ~/.local/bin
    ```
4.  **Restart your shell** or run `source ~/.config/fish/config.fish` to apply PATH changes.

## Usage

The `rrr` client script provides intuitive commands for managing your REPL sessions.

```bash
rrr --help
```

### Server Management

-   **Start the RRR server in the background:**
    ```bash
    rrr start
    ```
-   **Shut down the RRR server and all active REPL sessions:**
    ```bash
    rrr stop
    ```

### Session Management

-   **Create a new Julia REPL session with ID `myjuliasession`:**
    ```bash
    rrr +jl myjuliasession
    ```
-   **Create a new Python REPL session with ID `2`:**
    ```bash
    rrr +py 2
    ```
-   **Adding arguments to the command:**
    ```bash
    rrr +jl 3 --project --thread=auto
    ```
-   **Create a custom REPL session (e.g., Fish shell) with ID `3`:**
    > [!WARNING]
    > Dont do this! working with a repl requires an integration script,
    > and if it does not work, it would just make the server hang.
    ```bash
    rrr +none 3 fish
    ```
-   **Terminate a specific REPL session (e.g., session `1`):**
    ```bash
    rrr kill 1
    ```


### Running Code in Sessions

-   **Run a single line of code in session `1`:**
    ```bash
    rrr 1 -- "println(\"Hello from Julia!\")"
    ```
-   **Pipe multi-line code to session `2`:**
    File `my_script.py`:
    ```python
    x = 10
    print(f"The value of x is {x * 2}")
    ```
    Run it:
    ```bash
    cat my_script.py | rrr 2
    # Expected output: The value of x is 20
    ```

## Helix Editor Integration

To integrate RRR.jl directly into your Helix workflow, add the following keybindings to your `~/.config/helix/config.toml` file.

These bindings allow you to create/kill sessions and send selected code to a specific REPL session directly from Helix.

```toml
# --- RRR.jl Integration (Prompt-less) ---

# Normal mode: <space><space> then [j,p,k] then a number
[keys.normal.space.space.j]
"1" = ":sh rrr +jl 1"
"2" = ":sh rrr +jl 2"
"3" = ":sh rrr +jl 3"
"4" = ":sh rrr +jl 4"
"5" = ":sh rrr +jl 5"

[keys.normal.space.space.p]
"1" = ":sh rrr +py 1"
"2" = ":sh rrr +py 2"
"3" = ":sh rrr +py 3"
"4" = ":sh rrr +py 4"
"5" = ":sh rrr +py 5"

[keys.normal.space.space.k]
"1" = ":sh rrr kill 1"
"2" = ":sh rrr kill 2"
"3" = ":sh rrr kill 3"
"4" = ":sh rrr kill 4"
"5" = ":sh rrr kill 5"

# Select mode: <space><space> followed by a number sends code to that session
[keys.select.space.space]
"1" = ":pipe 'rrr 1'"
"2" = ":pipe 'rrr 2'"
"3" = ":pipe 'rrr 3'"
"4" = ":pipe 'rrr 4'"
"5" = ":pipe 'rrr 5'"
```

**To set up Helix integration:**

1.  **Copy the above TOML block** above.
2.  **Open your Helix configuration file:** `hx ~/.config/helix/config.toml`.
3.  **Paste the TOML block** at the end of the file.
4.  **Save the file** and restart Helix.

Now you can manage your REPLs and send code directly from your editor!
To start a session, in normal mode: `space>space>j/p/k>num` and to
run, select text then press `space>space` and the id of the instance
you want to run it in.

You can also pass code into a custom session(which does not have a 1-5 id)
by using helix's builtin pipe, which is exactly what rrr does,
simply select some text, hit `|` then `rrr <id>`, and helix will pipe
the selection to rrr instance `<id>` and replace with the command's output.

