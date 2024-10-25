#!/usr/bin/env python3

import subprocess
import sys
import re
from datetime import datetime
from threading import Thread

# Define the mapping between location codes and IP addresses or URLs
LOCATIONS = {
    "USA_E": "ec2.us-east-1.amazonaws.com",  # US East (Virginia)
    "USA_W": "ec2.us-west-1.amazonaws.com",  # US West (California)
    "UK": "ec2.eu-west-2.amazonaws.com",     # London
    "BR": "ec2.sa-east-1.amazonaws.com"      # São Paulo (Brazil)
}

# Set debugMode to True if you want to print the time of each ping
debugMode = False

def ping_single(hostname, results, index):
    try:
        # Execute the ping command
        result = subprocess.run(
            ["ping", "-c", "1", hostname],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        if result.returncode == 0:
            # Extract the round-trip time from the ping output
            match = re.search(r'time=(\d+\.?\d*) ms', result.stdout)
            if match:
                rtt = float(match.group(1))
                results[index] = rtt

                if debugMode:
                    print(f"{datetime.now()} - {result.stdout.splitlines()[-1].strip()}")
        else:
            results[index] = None

    except Exception as e:
        print(f"An error occurred: {e}")
        results[index] = None

def ping_host(hostname, count=5):
    threads = []
    results = [None] * count

    for i in range(count):
        thread = Thread(target=ping_single, args=(hostname, results, i))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()

    # Filter out None values in case any pings failed
    valid_results = [rtt for rtt in results if rtt is not None]

    if valid_results:
        average_rtt = sum(valid_results) / len(valid_results)
        return average_rtt
    else:
        return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <location>")
        print("Example: python script.py USA_E")
        sys.exit(1)

    location = sys.argv[1]

    if location not in LOCATIONS:
        print("Invalid location. Choose from: USA_E, USA_W, UK, BR")
        sys.exit(1)

    hostname = LOCATIONS[location]
    average_rtt = ping_host(hostname)

    if average_rtt is not None:
        print(f"{location:<17} {average_rtt:>12.2f} ms")
    else:
        print("Failed to calculate RTT")

#
