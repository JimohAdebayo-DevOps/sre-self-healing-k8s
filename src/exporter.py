import time
import random
from prometheus_client import start_http_server, Gauge

# Define the metric: 1 is Healthy, 0 is Failed
# This is the name you will search for in Grafana
raid_status_metric = Gauge('node_raid_status', 'Health status of the RAID array (1=OK, 0=FAIL)')

def check_raid_logic():
    """
    SRE Simulation: 95% chance the RAID is healthy.
    In production, this would be a subprocess call to 'mdadm'.
    """
    return 1 if random.random() > 0.05 else 0

if __name__ == '__main__':
    # Start the Prometheus exporter server on port 8000
    print("Starting RAID Exporter on port 8000...")
    start_http_server(8000)
    
    # Infinite loop to update the metric
    while True:
        status = check_raid_logic()
        raid_status_metric.set(status)
        
        # Log to terminal for debugging
        state = "HEALTHY" if status == 1 else "FAILED"
        print(f"Current RAID Status: {state} ({status})")
        
        # Wait 15 seconds before the next check
        time.sleep(15)
