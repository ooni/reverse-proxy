#!/bin/bash
CLUSTER_ID="{{ cluster_id }}"

# List all HSM tokens
echo "Listing all HSM tokens in the cluster..."
aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --query "Clusters[0].Hsms[*].HsmId"

# Function to delete an HSM token and wait for its deletion
delete_hsm_token() {
    HSM_ID=$1
    aws cloudhsmv2 delete-hsm --cluster-id $CLUSTER_ID --hsm-id $HSM_ID
    echo "Deleting HSM Token with ID: $HSM_ID..."
    while true; do
        STATE=$(aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --query "Clusters[0].Hsms[?HsmId=='$HSM_ID'] | length(@)")
        if [ "$STATE" -eq 0 ]; then
            echo "HSM Token with ID $HSM_ID deleted."
            break
        fi
        echo "Waiting for HSM Token with ID $HSM_ID to be deleted..."
        sleep 10
    done
}

# Delete all HSM tokens
HSM_IDS=$(aws cloudhsmv2 describe-clusters --filters clusterIds=$CLUSTER_ID --query "Clusters[0].Hsms[*].HsmId" --output text)
for HSM_ID in $HSM_IDS; do
    delete_hsm_token $HSM_ID
done

echo "All HSM tokens have been deleted."
