import argparse
import json
from pathlib import Path


def build_problem_statement(item: dict) -> str:
    resolved_issues = item.get('resolved_issues') or []
    if resolved_issues:
        issue = resolved_issues[0] or {}
        title = issue.get('title', '').strip()
        body = issue.get('body', '').strip()
        return '\n'.join(part for part in (title, body) if part)

    title = str(item.get('title', '')).strip()
    body = str(item.get('body', '')).strip()
    return '\n'.join(part for part in (title, body) if part)


def convert_item(item: dict, version: str) -> dict:
    org = str(item.get('org', '')).strip()
    repo = str(item.get('repo', '')).strip()
    number = str(item.get('number', '')).strip()
    base = item.get('base') or {}

    if not org or not repo or not number:
        raise ValueError(f'Missing org/repo/number in item: {item!r}')

    problem_statement = build_problem_statement(item)
    if not problem_statement:
        raise ValueError(f'Missing issue text in item: {item!r}')

    return {
        'repo': f'{org}/{repo}',
        'instance_id': f'{org}__{repo}-{number}',
        'problem_statement': problem_statement,
        'FAIL_TO_PASS': [],
        'PASS_TO_PASS': [],
        'base_commit': str(base.get('sha', '')).strip(),
        'version': version,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Convert a Dark Reader / Multi-SWE style dataset into a SWE-bench-compatible JSONL file.'
    )
    parser.add_argument(
        '--input',
        default='/root/multi-swe-bench/data/ts/darkreader__darkreader_dataset.jsonl',
        help='Path to the source JSONL dataset.',
    )
    parser.add_argument(
        '--output',
        default='/root/Ref/MopenHands/evaluation/benchmarks/swe_bench/data/darkreader_converted.jsonl',
        help='Path to write the converted JSONL dataset.',
    )
    parser.add_argument(
        '--version',
        default='0.1',
        help='Version string stored in the converted records.',
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    converted = 0
    with input_path.open('r', encoding='utf-8') as fin, output_path.open(
        'w', encoding='utf-8'
    ) as fout:
        for line in fin:
            line = line.strip()
            if not line:
                continue

            item = json.loads(line)
            output_item = convert_item(item, args.version)
            fout.write(json.dumps(output_item, ensure_ascii=False) + '\n')
            converted += 1

    print(f'Converted {converted} records from {input_path} to {output_path}')


if __name__ == '__main__':
    main()
