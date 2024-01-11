# Garbage Collection

Because our language in written in Lua and has garbage collection handled by Lua, we are essentially at the mercy of Lua's garbage collection scheme. This could have two possible effects: it is possible that the garbage collector could  operate as we would like and recognize when entities have gone out of scope. On the other hand (and the case I find more likey), it would have little idea about when to perform garbage collection and memory would accumulate.

The impact on our implementation would be that after some time, our programs would consume too much memory. We could possibly make our languages more "garbage-collection friendly" by structuring our compiler and virtual machine to act more in accordance with the underlying garbage collector. This would depend on the language - perhaps we could be more intentional in designating memory as no longer needed or structing function calls to trigger the Lua garbage collector.
