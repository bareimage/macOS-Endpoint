#!/bin/bash

# Function to check if file exists
check_file_exists() {
	local file="$1"
	[[ -f "$file" ]] || { echo "InstallHistory.plist not found at $file"; exit 1; }
}

# Function to format XML
format_xml() {
	xmllint --format -
}

# Function to process XML and extract app store entries
process_xml() {
	awk '
		BEGIN { FS = "[<>]"; OFS = "," }
		/<key>processName<\/key>/ { getline; processName = $3 }
		/<key>displayName<\/key>/ { getline; name = $3 }
		/<key>displayVersion<\/key>/ { getline; version = $3 }
		/<key>date<\/key>/ { getline; date = $3 }
		/<\/dict>/ {
			if (processName == "appstoreagent" && name != "" && version != "" && date != "") {
				print name, version, date
			}
			processName = ""; name = ""; version = ""; date = ""
		}
	'
}

# Function to sort entries by date
sort_entries() {
	sort -t',' -k3 -r
}

# Function to get currently installed App Store apps
get_current_apps() {
	find /Applications -path '*Contents/_MASReceipt/receipt' -maxdepth 4 -print | 
	sed 's#.app/Contents/_MASReceipt/receipt#.app#g; s#/Applications/##; s#.app$##'
}

# Function to filter and format entries
filter_and_format_entries() {
	local current_apps="$1"
	while IFS=',' read -r name version date; do
		if echo "$current_apps" | grep -q "^${name}$"; then
			echo "$name,$version,$date"
		fi
	done
}

# Main function to compose all operations
main() {
	local install_history="/Library/Receipts/InstallHistory.plist"
	
	check_file_exists "$install_history"
	
	local current_apps=$(get_current_apps)
	
	cat "$install_history" | 
	format_xml |
	process_xml |
	sort_entries |
	filter_and_format_entries "$current_apps"
}

# Execute the main function
main