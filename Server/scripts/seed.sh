#!/bin/bash
# Seed script to create the first conference
# Run after deploying and setting up the database

API_URL="${API_URL:-http://localhost:8080}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"

if [ -z "$ADMIN_TOKEN" ]; then
  echo "Error: ADMIN_TOKEN is required"
  echo "Usage: ADMIN_TOKEN=<jwt_token> ./seed.sh"
  exit 1
fi

echo "Creating try! Swift Tokyo 2026 conference..."

curl -X POST "$API_URL/api/v1/conferences" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "path": "tryswift-tokyo-2026",
    "displayName": "try! Swift Tokyo 2026",
    "year": 2026,
    "isOpen": true,
    "deadline": "2026-02-28T23:59:59Z",
    "startDate": "2026-04-12T09:00:00+09:00",
    "endDate": "2026-04-14T18:00:00+09:00",
    "location": "Tokyo, Japan",
    "websiteURL": "https://tryswift.jp",
    "description": {
      "en": "## Talk Guidelines\n\n- All talks will be held in a **single track**. It is a requirement for adoption to be able to finish speaking within each talk'\''s time limit.\n- All talks include **AI-powered multilingual simultaneous interpretation**.\n- Many people from all over the world come to Japan to participate in this community. Participants prefer **specialized technical talks**.\n- Non-technical talks and emotional talks also have room for adoption, but it is preferable that everyone who comes to the conference can enjoy it.\n- **Introductory content** or content specialized in specific situations is difficult to adopt.\n  - Example: General architecture and accessibility adopted by the product will not be adopted unless your expertise is recognized.\n- If you are basing on past appearances, please make all or part of this conference **new content**.",
      "ja": "## トークガイドライン\n\n- すべてのトークは**シングルトラック**で実施します。各講演の規定時間以内で話し切れることが採用条件です。\n- すべてのトークに**AIによる多言語同時通訳**が付きます。\n- 世界各地から参加者が来日します。参加者は**専門性の高い技術トーク**を好みます。\n- 技術的ではないものやエモーショナルなトークにも採用の余地はありますが、来場者全員が楽しめる内容が望ましいです。\n- **入門的な内容**や、特定の状況に特化した内容は採用が難しい傾向です。\n  - 例：製品で採用している一般的なアーキテクチャやアクセシビリティは、あなたの専門性が認められない限り採用されません。\n- 過去の登壇を基にする場合は、全体または一部を**新規の内容**にしてください。"
    }
  }'

echo ""
echo "Conference created!"
