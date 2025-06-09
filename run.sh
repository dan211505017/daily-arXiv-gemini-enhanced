
#!/bin/bash
set -e

echo "🚀 Starting Daily ArXiv Update Workflow..."

# --- 1. 使用北京时区获取正确的当天日期 ---
today=$(TZ=Asia/Shanghai date "+%Y-%m-%d")
yesterday=$(TZ=Asia/Shanghai date -d "yesterday" "+%Y-%m-%d")
echo "✅ Workflow date set to: ${today} (Asia/Shanghai)"

# --- 2. 定义所有文件名 ---
RAW_JSONL_FILE="data/${today}.jsonl"
UNIQUE_JSONL_FILE="data/${today}_unique.jsonl"
YESTERDAY_UNIQUE_FILE="data/${yesterday}_unique.jsonl"
ENHANCED_JSONL_FILE="data/${today}_unique_AI_enhanced_Chinese.jsonl"
FINAL_MD_FILE="data/${today}.md"

# --- 3. 运行 Scrapy 爬虫 ---
echo "--- Step 1: Crawling data from ArXiv ---"
(cd daily_arxiv && scrapy crawl arxiv -o ../${RAW_JSONL_FILE})
echo "✅ Raw data saved to ${RAW_JSONL_FILE}"

# --- 4. 运行去重脚本 ---
echo "--- Step 2: Deduplicating raw data ---"
python deduplicate.py ${RAW_JSONL_FILE} -o ${UNIQUE_JSONL_FILE}
echo "✅ Unique data saved to ${UNIQUE_JSONL_FILE}"

# --- 5. 新增：运行增量过滤脚本  ---
echo "--- Step 2: Filtering for new items only ---"
# 调用新脚本，比较今天的文件和过去两天的文件
python filter_new.py --today ${UNIQUE_JSONL_FILE} --previous-days ${PREVIOUS_DAY_FILES[@]} --output ${NEW_ONLY_JSONL_FILE}

# --- 6. 运行 AI 增强脚本 ---
echo "--- Step 4: Enhancing data with AI ---"
# 确保它的输入是去重后的文件
python ai/enhance.py --data ${UNIQUE_JSONL_FILE}
echo "✅ AI enhancement complete. Output is ${ENHANCED_JSONL_FILE}"

# --- 7. 运行 Markdown 生成脚本 ---
echo "--- Step 5: Converting JSONL to Markdown ---"
python to_md/convert.py --data ${ENHANCED_JSONL_FILE}
echo "✅ Markdown report generated at ${FINAL_MD_FILE}"

# --- 8. 更新主 README 文件 ---
echo "--- Step 6: Updating main README.md ---"
python update_readme.py
echo "✅ README.md updated."

echo "🎉 Workflow finished successfully!"
请帮我优化一下，比较今天与昨天和前天的内容如果存在重复这删去今天jsonl的该id所属字段
