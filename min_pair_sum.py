"""
Minimize Maximum Pair Sum

Given an array nums of even length n, pair up the elements into n/2 pairs
such that the maximum pair sum is minimized.

Strategy:
1. Sort the array
2. Pair smallest with largest, second smallest with second largest, etc.
3. This ensures large values are distributed across pairs rather than
   concentrated in a single pair.

Time Complexity: O(n log n) due to sorting
Space Complexity: O(1) if we don't count the input array
"""


def minPairSum(nums):
    """
    Minimize the maximum pair sum by optimally pairing elements.
    
    Args:
        nums: List of integers with even length
        
    Returns:
        The minimized maximum pair sum
    """
    # Sort the array
    nums.sort()
    
    n = len(nums)
    max_sum = 0
    
    # Pair smallest with largest, second smallest with second largest, etc.
    for i in range(n // 2):
        pair_sum = nums[i] + nums[n - 1 - i]
        max_sum = max(max_sum, pair_sum)
    
    return max_sum


# Test cases
if __name__ == "__main__":
    # Example 1
    nums1 = [3, 5, 2, 3]
    result1 = minPairSum(nums1)
    print(f"Input: {nums1}")
    print(f"Output: {result1}")
    print(f"Explanation: After sorting: {sorted(nums1)}")
    print(f"  Pairs: ({sorted(nums1)[0]}, {sorted(nums1)[-1]}) = {sorted(nums1)[0] + sorted(nums1)[-1]}, "
          f"({sorted(nums1)[1]}, {sorted(nums1)[-2]}) = {sorted(nums1)[1] + sorted(nums1)[-2]}")
    print(f"  Maximum: {result1}\n")
    
    # Example 2: More test cases
    test_cases = [
        [3, 5, 2, 3],
        [1, 1, 1, 1],
        [1, 2, 3, 4, 5, 6],
        [4, 1, 5, 1, 2, 5],
    ]
    
    for nums in test_cases:
        result = minPairSum(nums)
        sorted_nums = sorted(nums)
        pairs = []
        for i in range(len(nums) // 2):
            pairs.append((sorted_nums[i], sorted_nums[-1-i]))
        print(f"Input: {nums}")
        print(f"Sorted: {sorted_nums}")
        print(f"Pairs: {pairs}")
        print(f"Pair sums: {[a+b for a, b in pairs]}")
        print(f"Output: {result}\n")


# More concise version:
def minPairSumConcise(nums):
    """One-liner version"""
    nums.sort()
    return max(nums[i] + nums[-1-i] for i in range(len(nums) // 2))
