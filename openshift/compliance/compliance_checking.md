## Run below command to export the scan report into json file

oc -n openshift-compliance get compliancecheckresults -l 'compliance.openshift.io/check-status in (FAIL),compliance.openshift.io/automated-remediation' -o json > compliance_results.json

## Check the fail status from compliancecheckresults auto remediation
oc -n openshift-compliance get compliancecheckresults -l 'compliance.openshift.io/check-status in (FAIL),compliance.openshift.io/automated-remediation'

## Check the fail status from compliancecheckresults non-auto remediation
oc -n openshift-compliance get compliancecheckresults.compliance.openshift.io | grep FAIL

## Scan individually
oc apply -f - <<EOF
apiVersion: compliance.openshift.io/v1alpha1
kind: ComplianceScan
metadata:
  name: ocp4-cis-kubeadmin-removed
  namespace: openshift-compliance
spec:
  scanType: Node
  suite: ocp4-cis
EOF

## Run the scan manually
oc annotate compliancescan ocp4-cis compliance.openshift.io/rescan= -n openshift-compliance

## Check the current scan
oc get compliancescans -n openshift-compliance