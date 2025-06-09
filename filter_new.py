# filter_new.py
import json
import argparse
import os

def main():
    parser = argparse.ArgumentParser(
        description="Filter today's items, keeping only those not seen in previous days."
    )
    parser.add_argument("--today", required=True, help="Path to today's unique JSONL file.")
    parser.add_argument("--previous-days", nargs='+', help="Paths to previous days' unique JSONL files to compare against.")
    parser.add_argument("-o", "--output", required=True, help="Path for the output file with new items only.")
    args = parser.parse_args()

    # --- 1. 加载所有已经见过的 ID ---
    seen_ids = set()
    if args.previous_days:
        for prev_file_path in args.previous_days:
            if os.path.exists(prev_file_path):
                print(f"🔍 Loading IDs from previous day: {prev_file_path}")
                with open(prev_file_path, 'r', encoding='utf-8') as f:
                    for line in f:
                        try:
                            item = json.loads(line)
                            if 'id' in item:
                                seen_ids.add(item['id'])
                        except json.JSONDecodeError:
                            continue
            else:
                print(f"⚠️ Previous day file not found, skipping: {prev_file_path}")
    
    print(f"ℹ️ Loaded {len(seen_ids)} unique IDs from previous days.")

    # --- 2. 过滤今天的文件 ---
    new_items = []
    today_items_count = 0
    if not os.path.exists(args.today):
        print(f"❌ Error: Today's file not found: {args.today}")
        return

    with open(args.today, 'r', encoding='utf-8') as f:
        for line in f:
            today_items_count += 1
            try:
                item = json.loads(line)
                # 只有当 ID 存在且没有在之前见过时，才认为是“新”条目
                if item.get('id') and item['id'] not in seen_ids:
                    new_items.append(item)
            except json.JSONDecodeError:
                continue

    print(f"ℹ️ Processed {today_items_count} items from today. Found {len(new_items)} new items.")

    # --- 3. 写入只包含新条目的文件 ---
    # 如果没有任何新条目，我们仍然创建一个空文件，让下游脚本可以正常处理
    with open(args.output, 'w', encoding='utf-8') as f:
        for item in new_items:
            f.write(json.dumps(item) + '\n')
            
    print(f"✅ Saved {len(new_items)} new items to: {args.output}")

if __name__ == "__main__":
    main()
