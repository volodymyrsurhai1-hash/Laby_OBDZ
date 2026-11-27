import unittest
from pathlib import Path

from forward_chaining import forward_chain, load_facts, load_rule_set


INFERENCE_DIR = Path(__file__).resolve().parent
RULES, _, _ = load_rule_set(INFERENCE_DIR / "rules.json")


class ForwardChainingTests(unittest.TestCase):
    def test_run_one_matches_manual_acceptance_chain(self) -> None:
        facts = load_facts(INFERENCE_DIR / "facts-run1.json")
        result = forward_chain(RULES, facts)

        self.assertEqual(len(result.cycles), 4)
        self.assertEqual(
            [firing.rule_id for cycle in result.cycles for firing in cycle.firings],
            ["П1", "П5", "П7"],
        )
        self.assertIn("booking_can_be_accepted", result.final_facts)
        self.assertEqual(len(result.final_facts), 9)

    def test_run_two_matches_manual_rejection_chain(self) -> None:
        facts = load_facts(INFERENCE_DIR / "facts-run2.json")
        result = forward_chain(RULES, facts)

        self.assertEqual(len(result.cycles), 3)
        self.assertEqual(
            [firing.rule_id for cycle in result.cycles for firing in cycle.firings],
            ["П1", "П4", "П6", "П8"],
        )
        self.assertIn("booking_must_be_rejected", result.final_facts)
        self.assertEqual(len(result.final_facts), 10)

        rejection = result.provenance["booking_must_be_rejected"]
        self.assertEqual(
            rejection.premises,
            ("requested_slot_busy", "client_limit_reached"),
        )

    def test_unpaid_reservation_uses_rule_nine(self) -> None:
        facts = load_facts(INFERENCE_DIR / "facts-unpaid.json")
        result = forward_chain(RULES, facts)

        self.assertEqual(len(result.cycles), 2)
        self.assertEqual(result.cycles[0].firings[0].rule_id, "П9")
        self.assertIn("payment_not_recorded", result.final_facts)
        self.assertEqual(len(result.final_facts), 3)


if __name__ == "__main__":
    unittest.main()
