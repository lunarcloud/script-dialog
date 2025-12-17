# AI Instructions for script-dialog

This file provides specific context and instructions for AI coding agents to
interact effectively with this bash library.


## Project Overview

script-dialog is a GUI and TUI dialog abstraction library for OSes which bash runs on. It abstracts each "dialog" feature of the various tools, such as message boxes, progressbars, or file selectors.

The library intelligently selects the best available dialog interface based on:
- The desktop environment (KDE, GNOME, XFCE, etc.)
- Available dialog tools (kdialog, zenity, whiptail, dialog)
- Whether running in GUI or terminal mode
- Cross-platform compatibility (Linux, macOS, Windows/WSL)


## Technologies and Dependencies

* **Languages**: bash (minimum version: 4.0 for associative arrays)
* **Development Utilities**: [shellcheck]
* **Abstracted Utilities**: [zenity, kdialog, whiptail, dialog, echo, sudo]
* **Optional Tools**: screenshot utilities (grim, wayshot, gnome-screenshot, spectacle, import, scrot, maim)

## Project Structure

The repository is organized as follows:

* `script-dialog.sh`: Contains all code for the library. This is the main file to source in scripts.
* `test.sh`: Demonstrates all features of the library and serves as integration tests.
* `screenshot-dialogs.sh`: Utility for capturing screenshots of dialogs across different interfaces.
* `.github/workflows/analyze.yml`: CI workflow that runs shellcheck on all scripts.

## Code Style and Conventions

* Follow shellcheck recommendations strictly.
* Document all functions with clear descriptions of parameters and behavior.
* Use consistent indentation (2 spaces).
* Always quote variable expansions unless you specifically need word splitting.
* Always quote command substitutions: `"$(command)"` not `$(command)`.
* Use `[[ ]]` for pattern matching (wildcards, regex) and bash-specific features (case conversion).
* Use `[ ]` for basic POSIX-compatible tests (string equality, -z, -n, numeric comparisons).
* Use `command -v` instead of `which` for checking command existence.
* Separate variable declarations from assignments that run commands: `local var; var=$(command)` instead of `local var=$(command)`.
* Use shellcheck directives instead of exporting variables to avoid polluting the environment.

### Running Quality Checks Locally

Before committing code, developers should run:

```bash
# Restore dependencies (ubuntu/debian syntax)
sudo apt install shellcheck

# Run the check on all scripts (including cross-file sourcing)
shellcheck ./*.sh extras/*.sh -x

# Run integration tests (requires a terminal or GUI environment)
bash test.sh
```

All code must pass shellcheck with zero violations before committing.

## Bash-Specific Patterns and Best Practices

### Exit Code Handling and Cancellation

The library uses `SCRIPT_DIALOG_CANCEL_EXIT_CODE` (default: 124) to handle dialog cancellation consistently:

1. **In library functions**: When a user cancels a dialog (closes window, presses ESC, clicks Cancel), the function calls `exit "$SCRIPT_DIALOG_CANCEL_EXIT_CODE"`.

2. **In scripts using command substitution**: Functions called in `$(...)` run in a subshell. If they call `exit`, it only exits the subshell, not the parent script. To propagate the exit:

   ```bash
   # CORRECT - propagates cancellation to parent script
   NAME=$(inputbox "Enter name:" "$USER") || exit "$?"
   
   # WRONG - cancellation only exits the subshell
   NAME=$(inputbox "Enter name:" "$USER")
   ```

3. **Exit status capture timing**: In bash, `$?` must be captured immediately after a command, not after `if`/`fi`:

   ```bash
   # CORRECT - captures command exit status
   if [ "$INTERFACE" == "zenity" ]; then
       result=$(zenity --entry --text="$1" --entry-text="$2" 2>/dev/null)
       exit_status=$?  # Must be right after the command
   fi
   
   # WRONG - captures if statement exit status (always 0)
   if [ "$INTERFACE" == "zenity" ]; then
       result=$(zenity --entry --text="$1" --entry-text="$2" 2>/dev/null)
   fi
   exit_status=$?  # This is 0, not the zenity exit code!
   ```

### Variable Existence Checking

Use `${VAR+x}` to check if a variable is set (even if empty):

```bash
# Check if SCRIPT_DIALOG_CANCEL_EXIT_CODE is set
if [ -z "${SCRIPT_DIALOG_CANCEL_EXIT_CODE+x}" ]; then
    SCRIPT_DIALOG_CANCEL_EXIT_CODE=124
fi
```

### Platform Detection

The library detects platforms and desktop environments:
- macOS: `[[ $OSTYPE == darwin* ]]` (pattern matching)
- Windows/WSL: `[[ $OSTYPE == msys ]] || [[ $(uname -r | tr '[:upper:]' '[:lower:]') == *wsl* ]]` (pattern matching)
- Linux desktops: Detected via `$XDG_CURRENT_DESKTOP`, `$XDG_SESSION_DESKTOP`, or running processes via `pgrep -l "process-name"` (gnome-shell, mutter, kwin)

### Shellcheck Directives and Cross-File Variables

The library uses a modular structure where `init.sh` defines variables used across multiple files. To handle shellcheck warnings about these cross-file variables:

1. **For variables defined in init.sh and used elsewhere**:
   - Add `# shellcheck disable=SC2154` at the top of files that use variables from init.sh
   - This suppresses "variable is referenced but not assigned" warnings

2. **For variables exposed to library users**:
   - Add `# shellcheck disable=SC2034` at the file level in init.sh
   - This suppresses "variable appears unused" warnings for intentionally exposed variables
   - Do NOT export these variables to avoid polluting the user's environment

3. **For intentional command word splitting**:
   - Quote command substitutions: `"$([ "$RECMD_SCROLL" == true ] && echo "--scrolltext")"`
   - This prevents SC2046 warnings while maintaining correct behavior

Example:
```bash
# At the top of a file using init.sh variables
#!/usr/bin/env bash
# Multi-UI Scripting - Helper Functions

# Variables set in init.sh and used here
# shellcheck disable=SC2154

# Now you can use variables like $bold, $normal, $red without warnings
```

## Cross-Platform Considerations

### Platform-Specific Behavior

* **macOS**: Limited dialog tool availability, often falls back to CLI mode
* **Windows (WSL/MSYS)**: Detect as "windows" desktop, may have limited GUI access
* **Linux**: Full support for various desktop environments (KDE, GNOME, XFCE, etc.)
* **Wayland vs X11**: Screenshot utility must detect compositor for proper tool selection

### Testing Across Platforms

When making changes that could affect platform detection or dialog selection:

1. Test with different `$OSTYPE` values
2. Test with different desktop environments set in environment variables
3. Test with various dialog tools available/unavailable
4. Consider CI/CD limitations (headless environment)

## Testing Approaches

### Manual Testing

1. **Basic functionality**: Run `bash test.sh` to exercise all dialog types
2. **Specific interface**: Set `INTERFACE` before sourcing:
   ```bash
   INTERFACE=whiptail bash test.sh
   ```
3. **Force GUI/terminal**: Set `GUI=true` or `GUI=false`
4. **Cancel behavior**: Test cancellation on each dialog type

### Screenshot Testing

Use `screenshot-dialogs.sh` to capture visual evidence of changes:

```bash
# Capture all dialogs for a specific interface
./screenshot-dialogs.sh --interface zenity

# Capture a specific dialog across all interfaces
./screenshot-dialogs.sh --dialog yesno

# Custom output directory
./screenshot-dialogs.sh --output ./pr-screenshots
```

**Note**: Screenshots require a graphical environment and appropriate screenshot tools.

### Automated Testing (CI)

The GitHub Actions workflow runs shellcheck on all `.sh` files for every PR and direct commit to master. All code must pass shellcheck without errors or warnings.

The workflow is configured to:
- Run on all pull requests (via `pull_request` trigger)
- Run on direct commits to `master` branch (via `push` trigger)
- Avoid duplicate runs on PRs by not triggering `push` for non-master branches

## Common Patterns and Pitfalls to Avoid

### DO:
* Capture exit status immediately after the command that generates it
* Use `|| exit "$?"` after command substitutions that might be cancelled
* Quote variable expansions: `"$variable"` not `$variable`
* Quote command substitutions: `"$(command)"` not `$(command)`
* Separate variable declarations from assignments: `local var; var=$(cmd)` not `local var=$(cmd)`
* Use shellcheck directives for cross-file variables instead of exporting them
* Test with multiple interfaces (zenity, kdialog, whiptail, dialog)
* Document why you're disabling shellcheck rules if necessary
* Consider both GUI and TUI behavior when implementing features

### DON'T:
* Add features that only work on one OS or desktop environment
* Change the shell type from bash to sh or zsh
* Assume a specific dialog tool is always available
* Capture `$?` after an `if`/`fi` statement (it's always 0)
* Remove or modify cancel detection without thorough testing
* Break backward compatibility with existing scripts
* Copy complex patterns from other projects without understanding them
* Export variables unnecessarily - use shellcheck directives instead to avoid environment pollution
* Leave unquoted variables or command substitutions that trigger shellcheck warnings

## Recent Learnings from PR Feedback

From PR #28 (Add configurable exit on dialog cancellation):

1. **Refactoring for maintainability**: Reducing code duplication is good, but not at the expense of correctness. Some patterns can't be simplified due to bash semantics.

2. **Testing cancellation**: Always test the cancel/ESC key behavior after changes to dialog functions. It's easy to break accidentally.

3. **Documentation in code**: Complex bash patterns (like exit status handling in subshells) benefit from inline comments explaining the "why".

4. **Iterative improvement**: It's okay to make multiple small commits when addressing feedback. Better to get it right than to get it done quickly.

5. **Exit code selection**: Exit code 124 was chosen over 1 because:
   - It's distinctive and less likely to conflict with other meanings
   - It follows the `timeout` command convention (which also uses 124)
   - It's less generic than 1 or 2

From PR (Shellcheck compliance and CI improvements):

1. **Quoting is mandatory**: All variable expansions and command substitutions must be quoted to pass shellcheck. This prevents word splitting and globbing issues.

2. **Separate declarations from assignments**: Using `local var=$(command)` masks the command's exit status. Always separate them: `local var; var=$(command)` followed by `exit_status=$?`.

3. **Use shellcheck directives, not exports**: When variables are defined in `init.sh` and used in other sourced files:
   - Add `# shellcheck disable=SC2154` at the top of files using those variables
   - Add `# shellcheck disable=SC2034` in init.sh for variables exposed to library users
   - Do NOT export variables just to satisfy shellcheck - this pollutes the user's environment

4. **CI must catch issues early**: The GitHub Actions workflow now runs on all PRs and master commits, ensuring code quality before merge.

5. **Zero tolerance for shellcheck violations**: All code must pass `shellcheck ./*.sh extras/*.sh -x` with zero warnings or errors.

## Boundaries and Guardrails

* **NEVER** add a feature only supported on one OS or desktop environment.
* **NEVER** change the shell type from bash.
* **NEVER** take non-obvious code from other projects without full understanding.
* **NEVER** break cancel detection or exit code handling.
* **NEVER** remove shellcheck compliance.
* **ALWAYS** test changes with multiple dialog interfaces.
* **ALWAYS** consider both GUI and terminal mode.
* **ALWAYS** maintain backward compatibility with existing scripts.
