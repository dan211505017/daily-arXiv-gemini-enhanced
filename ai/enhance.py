import os
import json
import sys

import dotenv
import argparse
import time
import langchain_core.exceptions
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.prompts import (
  ChatPromptTemplate,
  SystemMessagePromptTemplate,
  HumanMessagePromptTemplate,
)
from structure import Structure
# --- 1. 获取脚本所在的目录 ---
# __file__ 是当前脚本的文件名
# os.path.dirname() 获取该文件所在的目录路径
script_dir = os.path.dirname(os.path.abspath(__file__))

# --- 2. 构造模板文件的绝对路径 ---
# os.path.join() 会智能地将目录和文件名拼接成一个完整的路径
template_path = os.path.join(script_dir, "template.txt")
system_path = os.path.join(script_dir, "system.txt")

# --- 3. 使用绝对路径打开文件 ---
try:
    with open(template_path, 'r', encoding='utf-8') as f:
        template = f.read()
    with open(system_path, 'r', encoding='utf-8') as f:
        system = f.read()
except FileNotFoundError as e:
    print(f"❌ Error: Template file not found. Ensure 'template.txt' and 'system.txt' are in the same directory as enhance.py.", file=sys.stderr)
    print(f"Details: {e}", file=sys.stderr)
    sys.exit(1) # 发现错误后立即退出，避免后续错误


def parse_args():
    """解析命令行参数"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=str, required=True, help="jsonline data file")
    return parser.parse_args()

def main():
    args = parse_args()
    model_name = os.environ.get("MODEL_NAME", 'gemini-2.0-flash')
    language = os.environ.get("LANGUAGE", 'Chinese')

    data = []
    with open(args.data, "r") as f:
        for line in f:
            data.append(json.loads(line))

    seen_ids = set()
    unique_data = []
    for item in data:
        if item['id'] not in seen_ids:
            seen_ids.add(item['id'])
            unique_data.append(item)

    data = unique_data

    print('Open:', args.data, file=sys.stderr)

    llm = ChatGoogleGenerativeAI(model=model_name).with_structured_output(Structure)
    print('Connect to:', model_name, file=sys.stderr)
    prompt_template = ChatPromptTemplate.from_messages([
        SystemMessagePromptTemplate.from_template(system),
        HumanMessagePromptTemplate.from_template(template=template)
    ])

    chain = prompt_template | llm

    for idx, d in enumerate(data):
        try:
            response: Structure = chain.invoke({
                "language": language,
                "content": d['summary']
            })
            d['AI'] = response.dict()
        except langchain_core.exceptions.OutputParserException as e:
            print(f"{d['id']} has an error: {e}", file=sys.stderr)
            d['AI'] = {
                 "tldr": "Error",
                 "motivation": "Error",
                 "method": "Error",
                 "result": "Error",
                 "conclusion": "Error"
            }
        with open(args.data.replace('.jsonl', f'_AI_enhanced_{language}.jsonl'), "a") as f:
            f.write(json.dumps(d) + "\n")

        print(f"Finished {idx+1}/{len(data)}", file=sys.stderr)
        time.sleep(3)

if __name__ == "__main__":
    main()
