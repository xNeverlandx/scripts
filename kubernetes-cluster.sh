#!/bin/bash

export PREFIX=prefix
export URL="your-domain.com"
export AWS_REGION="your-region"

printf "Please specify a cluster name\n"
read CLUSTER_NAME
export KOPS_CONFIG_BUCKET=${PREFIX}.kops-${CLUSTER_NAME}.config
export K8_CONFIG_BUCKET=${PREFIX}.k8-${CLUSTER_NAME}.config



###################################
# 1. Generate SSH key for cluster #
###################################

printf "\n Let's generate a new ssh keypair for this cluster\n"
ssh-keygen -t rsa -f ${PREFIX}-${CLUSTER_NAME}
export PUBLIC_SSH_KEY=./${PREFIX}-${CLUSTER_NAME}.pub


printf "  \n Now let's create a new cluster\n"



########################
# 2. Create S3 Buckets #
########################

printf "\n Create S3 buckets for kops and kubernetes config\n"
printf "  a) Creating S3 bucket for kops config…"
aws s3 ls | grep $KOPS_CONFIG_BUCKET > /dev/null
if [ $? -eq 0 ]
then
  printf " Bucket already exists\n\n"
else
  chronic aws s3api create-bucket \
    --bucket $KOPS_CONFIG_BUCKET \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=${AWS_REGION}

  chronic aws s3api put-bucket-versioning \
    --bucket $KOPS_CONFIG_BUCKET \
    --versioning-configuration Status=Enabled
  printf " \n"
fi

printf " Creating S3 bucket for kubernetes config…"
aws s3 ls | grep $K8_CONFIG_BUCKET > /dev/null
if [ $? -eq 0 ]
then
  printf " Bucket already exists\n\n"
else
  chronic aws s3api create-bucket \
    --bucket $K8_CONFIG_BUCKET \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION

  chronic aws s3api put-bucket-versioning \
    --bucket $K8_CONFIG_BUCKET \
    --versioning-configuration Status=Enabled
  printf " \n"
fi



###########################
# 3. Create IAM Resources #
###########################
printf "\n Create IAM user and group for kops\n"
printf " Creating IAM group for kops…"
aws iam list-groups | grep kops > /dev/null
if [ $? -eq 0 ]
then
  printf " IAM group 'kops' already exists\n"
else
  chronic aws iam create-group --group-name kops
  printf "\n"
fi

printf " Attaching IAM policies to kops usergroup…"
export policies="
AmazonEC2FullAccess
AmazonRoute53FullAccess
AmazonS3FullAccess
IAMFullAccess
AmazonVPCFullAccess"

new_policy_created=false
for policy in $policies; do
  check_arn=$(aws iam list-attached-group-policies --group-name kops | jq --arg policy $policy '.AttachedPolicies[] | select(.PolicyName == $policy) | .PolicyName' > /dev/null)
  if [ "$check_arn" = "null" ]
  then
    $new_policy_created=true
    aws iam attach-group-policy --policy-arn "arn:aws:iam::aws:policy/$policy" --group-name kops;
  fi
done
if [ "$new_policy_created" = true ]
then
  printf "\n"
else
  printf "Policies already exist\n"
fi

printf "Creating IAM user for kops…"
aws iam list-users | grep kops > /dev/null
if [ $? -eq 0 ]
then
  printf "IAM user 'kops' already exists\n"
else
  aws iam create-user --user-name kops
  aws iam add-user-to-group --user-name kops --group-name kops
  aws iam create-access-key --user-name kops
  printf "\n"
fi



##########################
# 4. Create kops cluster #
##########################
printf "\n Create new kops cluster\n"
kops create cluster \
  --state s3://${KOPS_CONFIG_BUCKET} \
  --ssh-public-key $PUBLIC_SSH_KEY \
  --cloud aws \
  --zones ${AWS_REGION}a \
  --topology private \
  --networking calico \
  --network-cidr=10.0.0.0/16 \
  --bastion \
  --master-size m3.medium \
  --node-size m3.medium \
  --node-count 4 \
  --yes \
  k8-${CLUSTER_NAME}.${URL}
printf "Successfully\n"



########################
# 5. Export kubeconfig #
########################
printf "\n Exporting kubeconfig from new cluster…"
# To export the kubectl configuration to a specific file we need to set the KUBECONFIG environment variable.
# see kops export kubecfg --help for further information
export KUBECONFIG=./kubeconfig
chronic kops export kubecfg k8-${CLUSTER_NAME}.${URL} --state=s3://${KOPS_CONFIG_BUCKET}
printf "Done\n"



#########################
# 6. Encrypt kubeconfig #
#########################
printf "\n Encrypting kubeconfig with OpenSSL…"
openssl enc -aes-256-cbc -salt -in kubeconfig -out kubeconfig.enc
printf "Done\n"



########################
# 7. Upload kubeconfig #
########################
printf "\n Uploading encrypted kubeconfig to S3…"
chronic aws s3 cp kubeconfig.enc s3://${K8_CONFIG_BUCKET}/kubeconfig.enc
printf "Done\n"



############
# 8. Done! #
############
printf "\n Finished!"
printf "\n You can see if the cluster is ready by running 'kops validate cluster --state s3://${KOPS_CONFIG_BUCKET} --name k8-${CLUSTER_NAME}.${URL}'\n"