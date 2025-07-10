#!/bin/sh

NAMESPACE="openshift-compliance"
CHECKS=$(oc get compliancecheckresults.compliance.openshift.io -n $NAMESPACE | grep FAIL | cut -f1 -d' ')

echo "NAME; DESCRIPTION; SEVERITY" > results.csv
for i in $CHECKS 
do
    DESCRIPTION=$(oc get compliancecheckresults.compliance.openshift.io $i -n $NAMESPACE -o jsonpath='{.description}')
    SEVERITY=$(oc get compliancecheckresults.compliance.openshift.io $i -n $NAMESPACE -o jsonpath='{.severity}')
    echo "$i; \"$DESCRIPTION\"; $SEVERITY" >> results.csv
done

echo "Compliance check results exported to results.csv"
