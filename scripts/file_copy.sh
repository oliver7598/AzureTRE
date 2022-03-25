#!bin/bash

Help()
{
   # Display Help
   echo "Used to copy files between storage accounts within a TRE Airlock as part of Ingress/Egress."
   echo "az login is required to be run prior to running this script."
   echo
   echo "Arguments          Mandatory       Description"
   echo "--airlock-sa       TRUE            Name of the airlock storage account."
   echo "--workspace-sa     TRUE            Name of the workspace storage account."
   echo "--operation-type   TRUE            Type of operation: ingress/egress"
   echo "--file-path        CONDITIONAL     The path to the file in the storage account.  Required if --pattern not provided."
   echo "--pattern          CONDITIONAL     The pattern to match for the files to copy.  Required if --file-path not provided."
   echo "--airlock-key      FALSE           Access key for the airlock storage account.  Aquired in script using users permissions if not provided."
   echo "--workspace-key    FALSE           Access key for the workspace storage account.  Aquired in script using users permissions if not provided."
   echo
}

while [ "$1" != "" ]; do
    case $1 in
    --airlock-sa)
        shift
        airlock_sa=$1
        ;;
    --workspace-sa)
        shift
        workspace_sa=$1
        ;;
    --airlock-key)
        shift
        airlock_key=$1
        ;;
    --workspace-key)
        shift
        workspace_key=$1
        ;;
    --operation-type)
        shift
        case $1 in
        ingress)
        ;;
        egress)
        ;;
        *)
            echo "operation-type must be 'ingress' or 'egress', not $1"
            exit 1
        esac
        operation_type=$1
        ;;
    --file-path)
        shift
        file_path=$1
        ;;
    --pattern)
        shift
        pattern=$1
        ;;
    *)
        echo "Unexpected argument: '$1'"
        usage
        ;;
    esac

    if [[ -z "$2" ]]; then
      # if no more args then stop processing
      break
    fi

    shift # remove the current value for `$1` and use the next
done

if [[ -z "$(az account show)" ]]; then
    exit 1
fi

if [[ -z "$airlock_sa" ]]; then
	echo "Missing required argument --airlock-sa"
	Help
    exit 1
else
	if [[ -z "$(az storage account show --name $airlock_sa)" ]]; then
		exit 1
	fi
fi

if [[ -z "$workspace_sa" ]]; then
	echo "Missing required argument --workspace-sa"
	Help
    exit 1
else
	if [[ -z "$(az storage account show --name $workspace_sa)" ]]; then
		exit 1
	fi
fi

if [[ -z "$operation_type" ]]; then
	echo "Missing required argument --operation-type"
	Help
    exit 1
fi
if [[ -z "$file_path" && -z "$pattern" ]]; then
    echo 'You must provide either --file-path or --pattern'
	Help
    exit 1
fi

rg=$(az storage account show --name ${airlock_sa} --output tsv --query "resourceGroup")

if [[ -z "$airlock_key" ]]; then
	airlock_key=$(az storage account keys list --account-name ${airlock_sa} --resource-group ${rg} --output tsv --query "[].[value][0]")
	if [[ -z $airlock_key ]]; then
		echo "Failed to retireve key for storage account ${airlock_sa}.  Please check your permissions."
		exit 1
	fi
fi

if [[ -z "$workspace_key" ]]; then
	workspace_key=$(az storage account keys list --account-name ${workspace_sa} --resource-group ${rg} --output tsv --query "[].[value][0]")
	if [[ -z $workspace_key ]]; then
		echo "Failed to retireve key for storage account ${workspace_sa}.  Please check your permissions."
		exit 1
	fi
fi

ip=$(curl ipecho.net/plain)

if [[ -z "$rg" ]]; then
    echo "Failed to return the resource group for storage account ${airlock_sa}.  Please check the name provided."
	exit 1
fi

if [[ $operation_type == "egress" ]]; then
    file_share="egress"
    src_sa=$workspace_sa
    src_key=$workspace_key
    dest_sa=$airlock_sa
    dest_key=$airlock_key
else
    file_share="ingress"
    src_sa=$airlock_sa
    src_key=$airlock_key
    dest_sa=$workspace_sa
    dest_key=$workspace_key
fi

echo "Creating network rule on storage account $workspace_sa for $ip"

result=$(az storage account network-rule add --account-name ${workspace_sa} --resource-group ${rg} --ip-address ${ip})

if [ -z "$result" ]; then
    echo "Failed to add $ip for storage account ${workspace_sa}.  Please check the name provided."
	exit 1
fi

echo "Waiting for network rule to take effect"

sleep 30s

if [[ ! -z "$file_path" ]]; then
    file=$(az storage file exists --path ${file_path} --share-name ${file_share} --account-name ${src_sa} --account-key ${src_key} --output tsv --query "exists")

    if [[ $file == "false" ]]; then
        echo "Failed to find $file_path in share ${file_share} for storage account ${src_sa}.  Please check the details provided."
    else
		echo "Copying ${file_path} from storage account ${src_sa}, file share ${file_share}."
		az storage file copy start --destination-path $file_path --destination-share $file_share --account-name $dest_sa --account-key $dest_key --source-account-name $src_sa --source-path $file_path --source-share $file_share --source-account-key $src_key
	fi
else
    files=$(az storage file list --share-name ${file_share} --account-name ${src_sa} --account-key ${src_key} --output tsv --query "[].[name]")

    echo "Copying ${#files[*]} file(s) from storage account ${src_sa}, file share ${file_share}."
    az storage file copy start-batch --pattern "$pattern" --source-account-name $src_sa --source-share $file_share --source-account-key $src_key --destination-share $file_share --account-name $dest_sa --account-key $dest_key
fi

echo "Removing network rule on storage account $workspace_sa for $ip"
result=$(az storage account network-rule remove --account-name $workspace_sa --resource-group $rg --ip-address $ip)
