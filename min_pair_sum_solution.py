"""
LeetCode 1877: Minimize Maximum Pair Sum in Array

Problem:
Given an array nums of even length n, pair up elements into n/2 pairs
such that the maximum pair sum is minimized.

Key Insight:
To minimize the maximum pair sum, we should pair the smallest elements
with the largest elements. This distributes large values across pairs
rather than concentrating them.

Algorithm:
1. Sort the array
2. Pair nums[i] with nums[n-1-i] for i from 0 to n/2-1
3. Return the maximum of all pair sums

Time Complexity: O(n log n) - dominated by sorting
Space Complexity: O(1) - excluding input array
"""


def minPairSum(nums):
    """
    Minimize the maximum pair sum by optimally pairing elements.
    
    Args:
        nums: List of integers with even length
        
    Returns:
        The minimized maximum pair sum
    """
    nums.sort()
    n = len(nums)
    max_sum = 0
    
    # Pair smallest with largest
    for i in range(n // 2):
        pair_sum = nums[i] + nums[n - 1 - i]
        max_sum = max(max_sum, pair_sum)
    
    return max_sum


# Alternative one-liner version
def minPairSumOneLiner(nums):
    nums.sort()
    return max(nums[i] + nums[-1-i] for i in range(len(nums) // 2))


# Test cases
if __name__ == "__main__":
    # Example 1
    nums1 = [3, 5, 2, 3]
    result1 = minPairSum(nums1)
    print(f"Example 1:")
    print(f"  Input: {nums1}")
    print(f"  Sorted: {sorted(nums1)}")
    sorted_nums = sorted(nums1)
    pairs = [(sorted_nums[0], sorted_nums[-1]), (sorted_nums[1], sorted_nums[-2])]
    print(f"  Optimal pairs: {pairs}")
    print(f"  Pair sums: {[a+b for a, b in pairs]}")
    print(f"  Output: {result1}")
    print(f"  Expected: 7\n")
    
    # Additional test cases
    test_cases = [
        ([3, 5, 2, 3], 7),
        ([1, 1, 1, 1], 2),
        ([1, 2, 3, 4, 5, 6], 7),
        ([4, 1, 5, 1, 2, 5], 6),
        ([1, 4, 3, 2], 5),
    ]
    
    print("Additional Test Cases:")
    for nums, expected in test_cases:
        result = minPairSum(nums)
        sorted_nums = sorted(nums)
        pairs = [(sorted_nums[i], sorted_nums[-1-i]) for i in range(len(nums) // 2)]
        status = "PASS" if result == expected else "FAIL"
        print(f"  [{status}] Input: {nums}")
        print(f"    Pairs: {pairs} -> Sums: {[a+b for a, b in pairs]}")
        print(f"    Result: {result} (Expected: {expected})")
        print()
