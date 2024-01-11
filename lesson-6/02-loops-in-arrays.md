# Loops In Arrays

In the provided example, Lua is show to have the ability to create circular references. A circular reference is when a one piece of code requires the result from a second piece of code, but the second piece of code requires the result from the first piece of code, resulting a closed loop.

JavaScript has the ability to create circular references:
```JavaScript
let a = []
a[0] = a
// <ref *1> [ [Circular *1] ]
```

But Elixir does not:
```Elixir
a = []
[a | a]
# [[]]

a = []
List.insert_at(a, 0, a)
# [[]]
```

This is because Elixir has immutable data structures. With immutable data structures, a modification to the data structure would actually create an new instance of the data structure. In order for circular references to be possible, the entity being referenced must first exist. If an entity does not exist, it cannot be referred to. Therefore, circular data structures are not possible in Elixir - you cannot refer to a data structure before it is created and any modification to a data structure results in a new data structure. Lists in Elixir are linked lists and linked lists are often used to create immutable data structures.

