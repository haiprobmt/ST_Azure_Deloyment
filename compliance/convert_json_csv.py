import pandas as pd
import json

# Load the JSON data
with open('d:/Work/ST/Infrastructure_ST_Devops/compliance/azure_cis_compliance_report.json') as json_file:
    data = json.load(json_file)

# Create a DataFrame from the JSON data
df = pd.json_normalize(data)

df_final = df[['resourceGroup', 'resourceId', 'resourceType', 'policyDefinitionReferenceId', 'policyDefinitionId']]

# Save the DataFrame to a CSV file
# df.to_csv('d:/Work/ST/Infrastructure_ST_Devops/compliance/azure_cis_compliance_report.csv', index=False)