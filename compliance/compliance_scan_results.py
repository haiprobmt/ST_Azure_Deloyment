import json
import pandas as pd

# Load JSON file
file_path = "/home/davidnguyen/st_terraform_linux/Infrastructure/compliance/compliance_results.json"  # Replace with your actual file path
with open(file_path, "r") as file:
    data = json.load(file)

# Extract required fields
records = []
for item in data.get("items", []):
    rule_name = item.get("metadata", {}).get("annotations", {}).get("compliance.openshift.io/rule", "")
    description = item.get("description", "")
    instructions = item.get("instructions", "")
    rationale = item.get("rationale", "")

    records.append({
        "name": rule_name,
        "description": description,
        "instructions": instructions,
        "rationale": rationale
    })

# Convert to DataFrame
df = pd.DataFrame(records)

# Save to CSV
csv_file_path = "/home/davidnguyen/st_terraform_linux/Infrastructure/compliance/compliance_results.csv"  # Replace with your desired output path
df.to_csv(csv_file_path, index=False)

print(f"CSV file saved at: {csv_file_path}")
