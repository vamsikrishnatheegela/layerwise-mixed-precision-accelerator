"""Unit tests for the independent mixed_precision_mac reference model."""
import random
import unittest

from reference_model import decode_operand, mac_step, signed_value


class ReferenceModelTests(unittest.TestCase):
    def test_int4_signed_boundaries(self):
        self.assertEqual(decode_operand(0x0, 0), 0)
        self.assertEqual(decode_operand(0x7, 0), 7)
        self.assertEqual(decode_operand(0x8, 0), -8)
        self.assertEqual(decode_operand(0xF, 0), -1)
        # Upper nibble must be ignored in INT4 mode.
        self.assertEqual(decode_operand(0xF8, 0), -8)

    def test_int8_signed_boundaries(self):
        self.assertEqual(decode_operand(0x7F, 1), 127)
        self.assertEqual(decode_operand(0x80, 1), -128)
        self.assertEqual(decode_operand(0xFF, 1), -1)

    def test_control_priority(self):
        self.assertEqual(
            mac_step(123, 7, 7, 0, enable=True, clear_acc=True), 0
        )
        self.assertEqual(
            mac_step(123, 7, 7, 0, enable=False, clear_acc=False), 123
        )
        self.assertEqual(
            mac_step(123, 7, 7, 0, rst_n=False), 0
        )

    def test_known_products(self):
        self.assertEqual(mac_step(0, 7, 7, 0), 49)
        self.assertEqual(mac_step(0, 0x8, 1, 0), -8)
        self.assertEqual(mac_step(0, -128, -128, 1), 16384)

    def test_accumulation_and_32_bit_wrap(self):
        self.assertEqual(mac_step(40, 3, 4, 1), 52)
        self.assertEqual(mac_step((1 << 31) - 1, 1, 1, 1), -(1 << 31))
        self.assertEqual(mac_step(-(1 << 31), -1, 1, 1), (1 << 31) - 1)

    def test_invalid_mode_rejected(self):
        with self.assertRaises(ValueError):
            decode_operand(1, 2)

    def test_deterministic_randomized_reference_invariants(self):
        rng = random.Random(0x4D4143)
        for _ in range(10_000):
            mode = rng.randrange(2)
            a = rng.randrange(256)
            b = rng.randrange(256)
            acc = signed_value(rng.getrandbits(32), 32)
            enable = bool(rng.getrandbits(1))
            clear = bool(rng.getrandbits(1))
            actual = mac_step(acc, a, b, mode, enable=enable, clear_acc=clear)
            self.assertGreaterEqual(actual, -(1 << 31))
            self.assertLessEqual(actual, (1 << 31) - 1)
            if clear:
                self.assertEqual(actual, 0)
            elif not enable:
                self.assertEqual(actual, acc)


if __name__ == "__main__":
    unittest.main(verbosity=2)
