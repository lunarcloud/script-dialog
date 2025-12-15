#!/usr/bin/env bash
# Screenshot utility for script-dialog
# https://github.com/lunarcloud/script-dialog
# LGPL-2.1 license
#
# This script helps demonstrate dialog features by running them with different
# interfaces and taking screenshots for documentation and PR evidence.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default values
OUTPUT_DIR="$SCRIPT_DIR/screenshots"
INTERFACE_TO_TEST=""
DIALOG_TYPE=""
SCREENSHOT_DELAY=0.5
SCREENSHOT_TOOL=""

# Detect if running on Wayland
IS_WAYLAND=false
if [ -n "$WAYLAND_DISPLAY" ]; then
    IS_WAYLAND=true
fi

# Available screenshot tools in order of preference
# Wayland-compatible tools: grim, wayshot, gnome-screenshot (on GNOME+Wayland), spectacle (on KDE+Wayland)
# X11 tools: import, scrot, maim
if [ "$IS_WAYLAND" = true ]; then
    SCREENSHOT_TOOLS=("grim" "wayshot" "gnome-screenshot" "spectacle" "import" "scrot" "maim")
else
    SCREENSHOT_TOOLS=("import" "scrot" "gnome-screenshot" "spectacle" "maim" "grim" "wayshot")
fi

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Take screenshots of script-dialog features using different interfaces.

OPTIONS:
    -i, --interface INTERFACE   Interface to test: zenity, kdialog, whiptail, dialog, echo
                                If not specified, will test all available interfaces
    -d, --dialog TYPE          Dialog type to test: info, warn, error, yesno, input,
                                progress, checklist, radiolist, filepicker, folderpicker,
                                datepicker, password, display-file, pause
                                If not specified, will test common dialog types
    -o, --output DIR           Output directory for screenshots (default: ./screenshots)
    -t, --tool TOOL            Screenshot tool to use: grim, wayshot, import, scrot,
                                gnome-screenshot, spectacle, maim (auto-detected if not specified)
                                Note: grim and wayshot are Wayland-native tools
    -w, --wait SECONDS         Delay before taking screenshot (default: 0.5)
    -h, --help                 Show this help message

EXAMPLES:
    # Screenshot all available interfaces with message-info
    $0 -d info

    # Screenshot zenity interface with all common dialogs
    $0 -i zenity

    # Screenshot whiptail with yesno dialog
    $0 -i whiptail -d yesno

    # Test all available interfaces with all common dialogs
    $0

EOF
}

# Function to detect available screenshot tool
detect_screenshot_tool() {
    for tool in "${SCREENSHOT_TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "$tool"
            return 0
        fi
    done
    return 1
}

# Function to take a screenshot
take_screenshot() {
    local output_file="$1"
    local window_id="$2"
    
    case "$SCREENSHOT_TOOL" in
        grim)
            # grim is Wayland-native, captures entire screen or specific output
            if [ -n "$window_id" ]; then
                # For specific windows, use slurp to select region
                if command -v slurp >/dev/null 2>&1; then
                    grim -g "$(slurp)" "$output_file" 2>/dev/null
                else
                    grim "$output_file" 2>/dev/null
                fi
            else
                grim "$output_file" 2>/dev/null
            fi
            ;;
        wayshot)
            # wayshot is another Wayland screenshot tool
            wayshot -f "$output_file" 2>/dev/null
            ;;
        import)
            if [ -n "$window_id" ]; then
                import -window "$window_id" "$output_file" 2>/dev/null
            else
                import -window root "$output_file" 2>/dev/null
            fi
            ;;
        scrot)
            if [ -n "$window_id" ]; then
                scrot -u "$output_file" 2>/dev/null
            else
                scrot "$output_file" 2>/dev/null
            fi
            ;;
        gnome-screenshot)
            if [ -n "$window_id" ]; then
                gnome-screenshot -w -f "$output_file" 2>/dev/null
            else
                gnome-screenshot -f "$output_file" 2>/dev/null
            fi
            ;;
        spectacle)
            if [ -n "$window_id" ]; then
                spectacle -a -b -n -o "$output_file" 2>/dev/null
            else
                spectacle -f -b -n -o "$output_file" 2>/dev/null
            fi
            ;;
        maim)
            if [ -n "$window_id" ]; then
                maim -i "$window_id" "$output_file" 2>/dev/null
            else
                maim "$output_file" 2>/dev/null
            fi
            ;;
        *)
            echo "Error: Unknown screenshot tool: $SCREENSHOT_TOOL" >&2
            return 1
            ;;
    esac
}

# Function to run a dialog and take screenshot
run_dialog_with_screenshot() {
    local interface="$1"
    local dialog_type="$2"
    local output_file="$OUTPUT_DIR/${interface}-${dialog_type}.png"
    
    echo "Testing $interface with $dialog_type..."
    
    # Set GUI flag based on interface
    local gui_value="false"
    if [ "$interface" == "zenity" ] || [ "$interface" == "kdialog" ]; then
        gui_value="true"
    fi
    
    # Create a temporary script that will run the dialog using environment variables
    local temp_script="/tmp/screenshot-dialog-$$.sh"
    
    cat > "$temp_script" << 'SCRIPT_EOF'
#!/usr/bin/env bash
# This script is generated dynamically and uses environment variables to avoid sed issues

# Source the library with the specified interface
source "$SCREENSHOT_SCRIPT_DIR/script-dialog.sh"

export APP_NAME="Script Dialog Demo"
export ACTIVITY="Screenshot Test"

# Run the dialog based on type
case "$SCREENSHOT_DIALOG_TYPE" in
    info)
        message-info "This is an informational message.\nSecond line of text."
        ;;
    warn)
        message-warn "This is a warning message.\nPlease pay attention!"
        ;;
    error)
        message-error "This is an error message.\nSomething went wrong!"
        ;;
    yesno)
        yesno "Do you want to continue?\nThis is a yes/no question." || true
        ;;
    input)
        inputbox "Please enter your name:" "John Doe" || true
        ;;
    password)
        password "Enter your password:" || true
        ;;
    pause)
        pause "Ready to continue?" || true
        ;;
    checklist)
        checklist "Select options:" 3 \
            "opt1" "Option 1" ON \
            "opt2" "Option 2" OFF \
            "opt3" "Option 3" ON || true
        ;;
    radiolist)
        radiolist "Choose one:" 3 \
            "opt1" "Option 1" OFF \
            "opt2" "Option 2" ON \
            "opt3" "Option 3" OFF || true
        ;;
    datepicker)
        datepicker || true
        ;;
    *)
        echo "Unknown dialog type: $SCREENSHOT_DIALOG_TYPE" >&2
        exit 1
        ;;
esac
SCRIPT_EOF

    chmod +x "$temp_script"
    
    # Export environment variables for the temp script
    export INTERFACE="$interface"
    export GUI="$gui_value"
    export SCREENSHOT_SCRIPT_DIR="$SCRIPT_DIR"
    export SCREENSHOT_DIALOG_TYPE="$dialog_type"
    
    # Run the dialog in background
    if [ "$interface" == "whiptail" ] || [ "$interface" == "dialog" ] || [ "$interface" == "echo" ]; then
        # For TUI/CLI interfaces, run in a new terminal if possible
        if command -v xterm >/dev/null 2>&1; then
            xterm -geometry 80x24 -hold -e "$temp_script" &
            local dialog_pid=$!
        elif command -v gnome-terminal >/dev/null 2>&1; then
            gnome-terminal -- bash -c "$temp_script; sleep 10" &
            local dialog_pid=$!
        else
            # Fallback: run directly but screenshot won't capture TUI properly
            "$temp_script" &
            local dialog_pid=$!
        fi
    else
        # For GUI interfaces, run directly with timeout
        timeout 10 "$temp_script" &
        local dialog_pid=$!
    fi
    
    # Wait for dialog to appear
    sleep "$SCREENSHOT_DELAY"
    
    # For GUI dialogs, wait a bit longer to ensure window is rendered
    if [ "$interface" == "zenity" ] || [ "$interface" == "kdialog" ]; then
        sleep 1
    fi
    
    # Take screenshot
    take_screenshot "$output_file" ""
    local screenshot_result=$?
    
    # Clean up - kill the process group to ensure child processes are also terminated
    if kill -0 "$dialog_pid" 2>/dev/null; then
        # Kill the entire process group (negative PID)
        kill -- -"$dialog_pid" 2>/dev/null || kill "$dialog_pid" 2>/dev/null || true
        sleep 0.2
        # Force kill if still running
        kill -9 -- -"$dialog_pid" 2>/dev/null || kill -9 "$dialog_pid" 2>/dev/null || true
    fi
    
    wait "$dialog_pid" 2>/dev/null || true
    
    # Clean up temp script
    rm -f "$temp_script"
    
    # Unset environment variables
    unset SCREENSHOT_SCRIPT_DIR SCREENSHOT_DIALOG_TYPE
    
    if [ $screenshot_result -eq 0 ] && [ -f "$output_file" ]; then
        echo "Screenshot saved: $output_file"
        return 0
    else
        echo "Failed to create screenshot: $output_file" >&2
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interface)
            INTERFACE_TO_TEST="$2"
            shift 2
            ;;
        -d|--dialog)
            DIALOG_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--tool)
            SCREENSHOT_TOOL="$2"
            shift 2
            ;;
        -w|--wait)
            SCREENSHOT_DELAY="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Detect screenshot tool if not specified
if [ -z "$SCREENSHOT_TOOL" ]; then
    if ! SCREENSHOT_TOOL=$(detect_screenshot_tool); then
        echo "Error: No screenshot tool found. Please install one of: ${SCREENSHOT_TOOLS[*]}" >&2
        if [ "$IS_WAYLAND" = true ]; then
            echo "For Wayland: sudo apt install grim (or wayshot)" >&2
        else
            echo "For X11: sudo apt install imagemagick" >&2
        fi
        echo "On macOS: brew install imagemagick" >&2
        exit 1
    fi
    echo "Using screenshot tool: $SCREENSHOT_TOOL"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Determine interfaces to test
if [ -n "$INTERFACE_TO_TEST" ]; then
    interfaces=("$INTERFACE_TO_TEST")
else
    interfaces=()
    # Check which interfaces are available
    command -v zenity >/dev/null 2>&1 && interfaces+=("zenity")
    command -v kdialog >/dev/null 2>&1 && interfaces+=("kdialog")
    command -v whiptail >/dev/null 2>&1 && interfaces+=("whiptail")
    command -v dialog >/dev/null 2>&1 && interfaces+=("dialog")
    interfaces+=("echo")  # Always available
fi

# Determine dialog types to test
if [ -n "$DIALOG_TYPE" ]; then
    dialog_types=("$DIALOG_TYPE")
else
    # Test common dialog types
    dialog_types=("info" "warn" "error" "yesno" "input")
fi

# Check if we have any interfaces to test
if [ ${#interfaces[@]} -eq 0 ]; then
    echo "Error: No dialog interfaces available to test" >&2
    exit 1
fi

echo "Interfaces to test: ${interfaces[*]}"
echo "Dialog types to test: ${dialog_types[*]}"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Run tests
success_count=0
fail_count=0

for interface in "${interfaces[@]}"; do
    for dialog_type in "${dialog_types[@]}"; do
        if run_dialog_with_screenshot "$interface" "$dialog_type"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        sleep 0.5  # Brief pause between tests
    done
done

echo ""
echo "Screenshot generation complete!"
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Screenshots saved in: $OUTPUT_DIR"

exit 0
