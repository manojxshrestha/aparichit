#!/bin/bash

# Simple Subdomain Enumeration Script
# Tools: Wayback Machine, Findomain, Subfinder, Assetfinder
# Output: Individual tool results in txt files, combined unique results in subdomain.txt

# ANSI colors
bold="\e[1m"
red="\e[31m"
green="\e[32m"
end="\e[0m"

# Banner
printf "%b\n" "${cyan}${bold}
               ___.
  ______ __ __ \\_ |__    ____    ____   __ __   _____
 /  ___/|  |  \\ | __ \\  / __ \\  /    \\ |  |  \\ /     \\
 \\___ \\ |  |  / | \\_\\ \\ \\  ___/ |   |  \\|  |  /|  Y Y  \\
/____  >|____/  |___  /  \\___  >|___|  /|____/ |__|_|  /
     \\/             \\/      \\/      \\/             \\/
               Subdomain Enumeration Tool
                      by ~/.manojxshrestha
${end}"

# Function to display usage
Usage() {
    while read -r line; do
        printf "%b\n" "$line"
    done <<-EOF
    \r${green}
    \r# Usage:
    \r  $0 -d <domain>
    \r
    \r# Options:
    \r  -d, --domain    Domain to enumerate (e.g., example.com)
    \r  -h, --help      Display this help message
    \r
    \r# Output:
    \r  - WaybackSubs.txt    Results from Wayback Machine
    \r  - FindomainSubs.txt  Results from Findomain
    \r  - SubfinderSubs.txt  Results from Subfinder
    \r  - AssetfinderSubs.txt Results from Assetfinder
    \r  - subdomain.txt      Combined unique subdomains
    \r
    \r# Example:
    \r  $0 -d example.com
    \r
    \r# Installation:
    \r  Install tools:
    \r    - findomain: Follow https://github.com/findomain/findomain
    \r    - subfinder: go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    \r    - assetfinder: go install github.com/tomnomnom/assetfinder@latest
    \r    - anew: go install github.com/tomnomnom/anew@latest
    \r${end}
EOF
    exit 1
}

# Validate domain format
validate_domain() {
    local domain=$1
    if ! [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${red}[-] Invalid domain format: $domain${end}"
        exit 1
    fi
}

# Check if tool is installed
check_tool() {
    local tool=$1
    command -v "$tool" >/dev/null 2>&1 || {
        echo -e "${red}[-] $tool not installed!${end}"
        exit 1
    }
}

# Wayback Machine
wayback() {
    echo -e "${bold}[+] Running Wayback Machine${end}"
    local outfile="WaybackSubs.txt"
    response=$(curl -s -w "%{http_code}" "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=")
    http_code=${response: -3}
    if [ "$http_code" != "200" ]; then
        echo -e "${red}[-] Wayback Machine API failed (HTTP $http_code)${end}"
        return
    fi
    echo "$response" | head -n -1 | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u > "$outfile"
    echo -e "Got ~ $(wc -l < "$outfile") subdomains\n"
}

# Findomain
Findomain() {
    check_tool findomain
    echo -e "${bold}[+] Running Findomain${end}"
    local outfile="FindomainSubs.txt"
    findomain -t "$domain" -q > "$outfile" 2>/dev/null
    echo -e "Got ~ $(wc -l < "$outfile") subdomains\n"
}

# Subfinder
Subfinder() {
    check_tool subfinder
    echo -e "${bold}[+] Running Subfinder${end}"
    local outfile="SubfinderSubs.txt"
    subfinder -d "$domain" -silent > "$outfile" 2>/dev/null
    echo -e "Got ~ $(wc -l < "$outfile") subdomains\n"
}

# Assetfinder
Assetfinder() {
    check_tool assetfinder
    echo -e "${bold}[+] Running Assetfinder${end}"
    local outfile="AssetfinderSubs.txt"
    assetfinder --subs-only "$domain" > "$outfile" 2>/dev/null
    echo -e "Got ~ $(wc -l < "$outfile") subdomains\n"
}

# Combine and deduplicate results
combine_results() {
    check_tool anew
    cat WaybackSubs.txt FindomainSubs.txt SubfinderSubs.txt AssetfinderSubs.txt 2>/dev/null | sort -u | anew subdomain.txt > /dev/null
    echo -e "${green}${bold}Subdomain Enumeration finished 🎉 ...check file subdomain.txt${end}"
}

# Main logic
Main() {
    # Validate domain
    [ "$domain" == "false" ] && {
        echo -e "${red}[-] Argument -d/--domain is required!${end}"
        Usage
    }
    validate_domain "$domain"

    # Run tools sequentially for cleaner output
    echo -e "\n${green}${bold}[+] Enumerating subdomains for $domain${end}\n"
    Subfinder
    Assetfinder
    Findomain
    wayback

    # Combine results
    combine_results
}

# Initialize variables
domain=false

# Parse arguments
while [ -n "$1" ]; do
    case $1 in
        -d|--domain)
            domain="$2"
            shift ;;
        -h|--help)
            Usage ;;
        *)
            echo -e "${red}[-] Unknown option: $1${end}"
            Usage ;;
    esac
    shift
done

Main
