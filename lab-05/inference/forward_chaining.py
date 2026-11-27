#!/usr/bin/env python3
"""Застосування правил прямого виведення, заданих у JSON."""

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, FrozenSet, List, Optional, Sequence, Set, Tuple


@dataclass(frozen=True)
class Rule:
    rule_id: str
    all_of: Tuple[str, ...]
    any_of: Tuple[str, ...]
    conclusion: str


@dataclass(frozen=True)
class Firing:
    rule_id: str
    premises: Tuple[str, ...]
    conclusion: str


@dataclass(frozen=True)
class Cycle:
    number: int
    firings: Tuple[Firing, ...]


@dataclass(frozen=True)
class InferenceResult:
    initial_facts: FrozenSet[str]
    final_facts: FrozenSet[str]
    cycles: Tuple[Cycle, ...]
    provenance: Dict[str, Firing]
    fired_rule_ids: FrozenSet[str]


def _fact_list(value: object, location: str, allow_empty: bool) -> Tuple[str, ...]:
    if not isinstance(value, list):
        raise ValueError(f"{location}: очікується список текстових фактів.")
    if not allow_empty and not value:
        raise ValueError(f"{location}: список не може бути порожнім.")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        raise ValueError(f"{location}: кожен факт має бути непорожнім рядком.")
    if len(set(value)) != len(value):
        raise ValueError(f"{location}: список містить повторювані факти.")
    return tuple(value)


def _read_json(path: Path) -> object:
    try:
        with path.open("r", encoding="utf-8") as source:
            return json.load(source)
    except json.JSONDecodeError as error:
        raise ValueError(
            f"{path}: некоректний JSON у рядку {error.lineno}, "
            f"стовпці {error.colno}: {error.msg}"
        ) from error


def load_rule_set(path: Path) -> Tuple[List[Rule], List[str], Dict[str, str]]:
    data = _read_json(path)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: кореневе значення має бути JSON-об'єктом.")

    raw_rules = data.get("rules")
    if not isinstance(raw_rules, list) or not raw_rules:
        raise ValueError(f"{path}: поле 'rules' має бути непорожнім списком.")

    rules: List[Rule] = []
    seen_rule_ids: Set[str] = set()
    for index, raw_rule in enumerate(raw_rules, start=1):
        location = f"{path}: rules[{index - 1}]"
        if not isinstance(raw_rule, dict):
            raise ValueError(f"{location}: очікується JSON-об'єкт.")

        rule_id = raw_rule.get("id")
        conclusion = raw_rule.get("then")
        if not isinstance(rule_id, str) or not rule_id.strip():
            raise ValueError(f"{location}: поле 'id' має бути непорожнім рядком.")
        if rule_id in seen_rule_ids:
            raise ValueError(f"{location}: повторюється ID правила {rule_id!r}.")
        if not isinstance(conclusion, str) or not conclusion.strip():
            raise ValueError(f"{location}: поле 'then' має бути непорожнім рядком.")

        all_of = _fact_list(raw_rule.get("all", []), f"{location}.all", True)
        any_of = _fact_list(raw_rule.get("any", []), f"{location}.any", True)
        if not all_of and not any_of:
            raise ValueError(f"{location}: правило має містити 'all' або 'any'.")

        rules.append(Rule(rule_id, all_of, any_of, conclusion))
        seen_rule_ids.add(rule_id)

    goals = list(_fact_list(data.get("goals", []), f"{path}: goals", True))
    raw_labels = data.get("labels", {})
    if not isinstance(raw_labels, dict):
        raise ValueError(f"{path}: поле 'labels' має бути JSON-об'єктом.")
    labels: Dict[str, str] = {}
    for fact, label in raw_labels.items():
        if not isinstance(fact, str) or not fact.strip():
            raise ValueError(f"{path}: ключі 'labels' мають бути назвами фактів.")
        if not isinstance(label, str) or not label.strip():
            raise ValueError(f"{path}: описи фактів у 'labels' мають бути рядками.")
        labels[fact] = label

    return rules, goals, labels


def load_facts(path: Path) -> Set[str]:
    data = _read_json(path)
    return set(_fact_list(data, str(path), False))


def _matches(rule: Rule, facts: FrozenSet[str]) -> Optional[Tuple[str, ...]]:
    if not set(rule.all_of).issubset(facts):
        return None

    matched_any = tuple(fact for fact in rule.any_of if fact in facts)
    if rule.any_of and not matched_any:
        return None

    return rule.all_of + matched_any


def forward_chain(rules: Sequence[Rule], initial_facts: Set[str]) -> InferenceResult:
    facts = set(initial_facts)
    provenance: Dict[str, Firing] = {}
    fired_rule_ids: Set[str] = set()
    cycles: List[Cycle] = []

    while True:
        cycle_number = len(cycles) + 1
        facts_at_cycle_start = frozenset(facts)
        pending: List[Firing] = []
        pending_conclusions: Set[str] = set()

        for rule in rules:
            premises = _matches(rule, facts_at_cycle_start)
            if premises is None:
                continue
            if rule.conclusion in facts_at_cycle_start:
                continue
            if rule.conclusion in pending_conclusions:
                continue

            pending.append(Firing(rule.rule_id, premises, rule.conclusion))
            pending_conclusions.add(rule.conclusion)

        if not pending:
            cycles.append(Cycle(cycle_number, ()))
            break

        for firing in pending:
            facts.add(firing.conclusion)
            provenance[firing.conclusion] = firing
            fired_rule_ids.add(firing.rule_id)

        cycles.append(Cycle(cycle_number, tuple(pending)))

    return InferenceResult(
        initial_facts=frozenset(initial_facts),
        final_facts=frozenset(facts),
        cycles=tuple(cycles),
        provenance=provenance,
        fired_rule_ids=frozenset(fired_rule_ids),
    )


def _describe(fact: str, labels: Dict[str, str]) -> str:
    label = labels.get(fact)
    return f"{fact} — {label}" if label else fact


def _print_explanation(
    fact: str,
    provenance: Dict[str, Firing],
    labels: Dict[str, str],
    indent: int = 0,
) -> None:
    prefix = "  " * indent
    firing = provenance.get(fact)
    if firing is None:
        print(f"{prefix}{_describe(fact, labels)} (початковий факт)")
        return

    print(f"{prefix}{_describe(fact, labels)} (висновок {firing.rule_id})")
    for premise in firing.premises:
        _print_explanation(premise, provenance, labels, indent + 1)


def print_result(
    result: InferenceResult,
    rules: Sequence[Rule],
    goals: Sequence[str],
    labels: Dict[str, str],
) -> None:
    print(f"Початкові факти ({len(result.initial_facts)}):")
    for fact in sorted(result.initial_facts):
        print(f"- {_describe(fact, labels)}")

    for cycle in result.cycles:
        print(f"\nЦикл {cycle.number}:")
        if not cycle.firings:
            print("  Нових фактів немає; досягнуто нерухомої точки.")
            continue
        for firing in cycle.firings:
            print(
                f"  {firing.rule_id}: "
                f"{_describe(firing.conclusion, labels)}"
            )

    print(
        f"\nУ нерухомій точці: {len(result.final_facts)} фактів "
        f"усього, нових висновків: {len(result.provenance)}."
    )

    not_fired = [
        rule.rule_id for rule in rules
        if rule.rule_id not in result.fired_rule_ids
    ]
    print("\nПравила, що не вивели нових фактів:")
    print(", ".join(not_fired) if not_fired else "немає")

    print("\nКінцеві цілі:")
    if not goals:
        print("  У файлі правил цілі не задані.")
        return
    for goal in goals:
        if goal not in result.final_facts:
            print(f"- Не виведено: {_describe(goal, labels)}")
            continue
        print(f"- Виведено: {_describe(goal, labels)}")
        _print_explanation(goal, result.provenance, labels, indent=1)


def main(argv: Optional[Sequence[str]] = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="Застосовує зовнішні правила до зовнішнього набору фактів."
    )
    parser.add_argument("--rules", required=True, type=Path, help="JSON-файл правил")
    parser.add_argument("--facts", required=True, type=Path, help="JSON-файл фактів")
    arguments = parser.parse_args(argv)

    try:
        rules, goals, labels = load_rule_set(arguments.rules)
        facts = load_facts(arguments.facts)
    except (OSError, ValueError) as error:
        parser.error(str(error))

    result = forward_chain(rules, facts)
    print_result(result, rules, goals, labels)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
