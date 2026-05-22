#!/usr/bin/env python3

"""
Simple test suite — used in Day 44 CI pipeline.
Tests basic utility functions:
- even/odd check
- palindrome check
- fizzbuzz

Exit code:
0 = all tests pass
non-zero = failure (pipeline goes red)
"""

import sys


# ==============================
# Utility Functions
# ==============================


# Function 1:
# Check if number is even
def is_even(n):

    # % = modulo operator
    #
    # n % 2
    # returns remainder after division by 2
    #
    # Even number => remainder 0
    return n % 2 == 0



# Function 2:
# Check if word is palindrome
#
# palindrome:
# same forward and backward
#
# Examples:
# madam
# racecar
def is_palindrome(s):

    # Beginner improvement:
    #
    # lower()
    # converts uppercase to lowercase
    #
    # replace(" ", "")
    # removes spaces
    #
    # This allows:
    # "A man a plan a canal Panama"
    # to work correctly
    cleaned = s.lower().replace(" ", "")

    # [::-1]
    # reverses string
    return cleaned == cleaned[::-1]



# Function 3:
# FizzBuzz logic
def fizzbuzz(n):

    # Must check divisible by 15 FIRST
    #
    # because:
    # 15 is divisible by BOTH 3 and 5
    if n % 15 == 0:
        return "FizzBuzz"

    elif n % 3 == 0:
        return "Fizz"

    elif n % 5 == 0:
        return "Buzz"

    else:
        return str(n)



# ==============================
# Simple Test Framework
# ==============================


# Track failed tests
failures = 0


# Track passed tests
passed = 0



# check() compares expected vs actual result
def check(test_name, expected, actual):

    # global means:
    # use variables from outside function
    global passed, failures


    # Test PASSED
    if expected == actual:

        # FIXED:
        # f-string syntax
        #
        # WRONG:
        # print(f "hello")
        #
        # CORRECT:
        # print(f"hello")
        print(f"PASS: {test_name}")

        passed += 1


    # Test FAILED
    else:

        print(f"FAIL: {test_name}")

        print(f"Expected: {expected}")

        print(f"Actual: {actual}")

        failures += 1



# ==============================
# Run Tests
# ==============================


print()


# --------------------------------
# Test is_even()
# --------------------------------

check("2 is even", True, is_even(2))

check("5 is even", False, is_even(5))

check("0 is even", True, is_even(0))

check("-4 is even", True, is_even(-4))


print()



# --------------------------------
# Test palindrome
# --------------------------------

check("madam palindrome", True, is_palindrome("madam"))

check("hello palindrome", False, is_palindrome("hello"))

check("'racecar' is palindrome", True, is_palindrome("racecar"))

check("'hello' is not palindrome", False, is_palindrome("hello"))


# NOW this works correctly
# because we improved function
check(
    "'A man a plan a canal Panama'",
    True,
    is_palindrome("A man a plan a canal Panama")
)

check("empty string is palindrome", True, is_palindrome(""))


print()



# --------------------------------
# Test fizzbuzz
# --------------------------------

check("3 => Fizz", "Fizz", fizzbuzz(3))

check("5 => Buzz", "Buzz", fizzbuzz(5))

check("15 => FizzBuzz", "FizzBuzz", fizzbuzz(15))

check("7 => 7", "7", fizzbuzz(7))

check("fizzbuzz(1) == '1'", "1", fizzbuzz(1))

check("fizzbuzz(30) == 'FizzBuzz'", "FizzBuzz", fizzbuzz(30))


print()



# ==============================
# Final Result
# ==============================


# Print summary FIRST
#
# IMPORTANT:
# must happen BEFORE exit()
#
# because exit() stops program immediately
print(f"=== Results: {passed} passed, {failures} failed ===")



# If any test failed
# exit with non-zero code
if failures > 0:

    print(f"\nFAILED TESTS: {failures}")

    # Non-zero exit code = CI failure
    #
    # GitHub Actions sees:
    # exit(1)
    #
    # and marks pipeline RED ❌
    sys.exit(1)



# If all tests passed
print("\nALL TESTS PASSED")


# exit(0) means success
#
# GitHub Actions marks pipeline GREEN ✅
sys.exit(0)
