#!/bin/bash
set -e

echo "🚀 Starting Daily Cosmetic Tech Update Workflow..."

# --- 1. 定义日期和文件名 ---
today=$(TZ=Asia/Shanghai date "+%Y-%m-%d")
yesterday=$(TZ=Asia/Shanghai date -d "1 day ago" "+%Y-%m-%d")
day_before_yesterday=$(TZ=Asia/Shanghai date -d "2 days ago" "+%Y-%m-%d")
echo "✅ Workflow date set to: ${today} (Asia/Shanghai)"

RAW_JSONL_FILE="data/${today}.jsonl"
UNIQUE_JSONL_FILE="data/${today}_unique.jsonl"
NEW_ONLY_JSONL_FILE="data/${today}_new_only.jsonl" # 只包含新条目的文件
ENHANCED_JSONL_FILE="data/${today}_new_only_AI_enhanced_Chinese.jsonl" # AI 增强文件名也相应改变
FINAL_MD_FILE="data/${today}.md"

PREVIOUS_DAY_FILES=("data/${yesterday}_unique.jsonl" "data/${day_before_yesterday}_unique.jsonl")

# --- 2. 爬取和去重 (保持不变) ---
echo "--- Step 1: Crawling and Deduplicating Today's Data ---"
(cd daily_cosmetic_tech && scrapy crawl cosmetic_tech -o ../${RAW_JSONL_FILE})
python deduplicate.py ${RAW_JSONL_FILE} -o ${UNIQUE_JSONL_FILE}
echo "✅ Crawling and deduplication complete for today."

# --- 3. 【核心修改】运行增量过滤脚本 ---
echo "--- Step 2: Filtering for new items only ---"
# 调用新脚本，比较今天的文件和过去两天的文件
python filter_new.py --today ${UNIQUE_JSONL_FILE} --previous-days ${PREVIOUS_DAY_FILES[@]} --output ${NEW_ONLY_JSONL_FILE}

# --- 4. 检查是否有新内容，如果没有则退出 ---
echo "--- Step 3: Checking if there is any new content ---"
# -s 检查文件是否存在且不为空
if [ ! -s "${NEW_ONLY_JSONL_FILE}" ]; then
    echo "ℹ️  No new items found compared to the last 2 days. Exiting workflow."
    # 清理当天的临时文件
    rm "$RAW_JSONL_FILE" "$UNIQUE_JSONL_FILE" "$NEW_ONLY_JSONL_FILE"
    exit 0
fi
echo "✅ New items found. Proceeding to AI enhancement."

# --- 5. 运行 AI 增强脚本 ---
echo "--- Step 4: Enhancing new items with AI ---"
# **确保输入是只包含新条目的文件**
python ai/enhance.py --data ${NEW_ONLY_JSONL_FILE}
echo "✅ AI enhancement complete. Output is ${ENHANCED_JSONL_FILE}"
python deduplicate.py ${ENHANCED_JSONL_FILE} -o ${ENHANCED_JSONL_FILE}

# --- 6. 运行 Markdown 生成脚本 ---
echo "--- Step 5: Converting JSONL to Markdown ---"
# **确保输入是 AI 增强后的“新条目”文件**
python to_md/convert.py --data ${ENHANCED_JSONL_FILE}
echo "✅ Markdown report generated at ${FINAL_MD_FILE}"

# --- 7. 更新主 README 文件 ---
echo "--- Step 6: Updating main README.md ---"
python update_readme.py
echo "✅ README.md updated."

echo "🎉 Workflow finished successfully!"
