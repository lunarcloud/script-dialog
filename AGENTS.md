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
* Prefer `[[ ]]` over `[ ]` for conditional tests (bash-specific).
* Use `command -v` instead of `which` for checking command existence.

### Running Quality Checks Locally

Before committing code, developers should run:

```bash
# Restore dependencies (ubuntu/debian syntax)
sudo apt install shellcheck

# Run the check on all scripts
shellcheck script-dialog.sh
shellcheck test.sh
shellcheck screenshot-dialogs.sh

# Or check all at once
shellcheck ./*.sh -x

# Run integration tests (requires a terminal or GUI environment)
bash test.sh
```

And correct any remaining issues reported.

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
   if [[ "$INTERFACE" == "zenity" ]]; then
       result=$(zenity --entry --text="$1" --entry-text="$2" 2>/dev/null)
       exit_status=$?  # Must be right after the command
   fi
   
   # WRONG - captures if statement exit status (always 0)
   if [[ "$INTERFACE" == "zenity" ]]; then
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
- macOS: `$OSTYPE == darwin*`
- Windows/WSL: `$OSTYPE == msys` or `uname -r` contains "wsl"
- Linux desktops: Detected via `$XDG_CURRENT_DESKTOP`, `$XDG_SESSION_DESKTOP`, or running processes

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

The GitHub Actions workflow runs shellcheck on all `.sh` files. All code must pass shellcheck without errors.

## Common Patterns and Pitfalls to Avoid

### DO:
* Capture exit status immediately after the command that generates it
* Use `|| exit "$?"` after command substitutions that might be cancelled
* Quote variable expansions: `"$variable"` not `$variable`
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

## Boundaries and Guardrails

* **NEVER** add a feature only supported on one OS or desktop environment.
* **NEVER** change the shell type from bash.
* **NEVER** take non-obvious code from other projects without full understanding.
* **NEVER** break cancel detection or exit code handling.
* **NEVER** remove shellcheck compliance.
* **ALWAYS** test changes with multiple dialog interfaces.
* **ALWAYS** consider both GUI and terminal mode.
* **ALWAYS** maintain backward compatibility with existing scripts.
