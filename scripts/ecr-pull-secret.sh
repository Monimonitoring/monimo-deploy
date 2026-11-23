#!/usr/bin/env bash
# 로컬 쿠버네티스가 ECR 에서 이미지를 받을 수 있게 apm 네임스페이스에 Secret ecr-pull 을 넣는다 (overlays/local-ecr).
#
# 토큰은 내 AWS 자격증명(aws configure)으로 받고 12시간 뒤 만료된다. 만료되면 이 스크립트를 다시 친다 :
# 떠 있는 파드는 이미 받은 이미지로 계속 돌고, 새 태그를 받을 때만 ImagePullBackOff 가 난다.
# EKS 에서는 필요 없다 : 노드의 IAM 역할로 kubelet 이 직접 로그인한다
set -euo pipefail
REGION="${AWS_REGION:-ap-northeast-2}"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

kubectl create namespace apm --dry-run=client -o yaml | kubectl apply -f - > /dev/null
kubectl -n apm create secret docker-registry ecr-pull \
  --docker-server="$REGISTRY" \
  --docker-username=AWS \
  --docker-password="$(aws ecr get-login-password --region "$REGION")" \
  --dry-run=client -o yaml | kubectl apply -f - > /dev/null
echo "✓ apm/ecr-pull → ${REGISTRY} (12시간 뒤 만료 : $(date -v+12H '+%m/%d %H:%M' 2>/dev/null || date -d '+12 hours' '+%m/%d %H:%M'))"
