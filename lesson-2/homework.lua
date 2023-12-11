-- 3 - Stack Machines

-- a) Manually execute the following stack-machine program
--
-- | push 4   |   |         |   |         |   |         |    |      |    |      |   |     |   |  |    |
-- | push 2   |   | push 2  |   |         |   |         |    |      |    |      |   |     |   |  |    |
-- | push 24  |   | push 24 |   | push 24 |   |         |    |      |    |      |   |     |   |  |    |
-- | push 21  |   | push 21 |   | push 21 |   | push 21 |    |      | 21 |      |   |     |   |  |    |
-- | sub      |   | sub     |   | sub     |   | sub     | 24 | sub  | 24 |      | 3 |     |   |  |    |
-- | mult     |   | mult    |   | mult    | 2 | mult    |  2 | mult |  2 | mult | 2 |     | 6 |  |    |
-- | add      |   | add     | 4 | add     | 4 | add     |  4 | add  |  4 | add  | 4 | add | 4 |  | 10 |

-- b) What arithmetic expression would generate that previous program?

print(4 + (2 * (24 - 21)))
