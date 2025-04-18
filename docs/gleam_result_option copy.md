# Understanding Result and Option in Gleam

## Quick Reference

### Option
- Represents presence/absence of a value
  - `Some(value)` - Value is present
  - `None` - Value is absent
- Use for: Optional parameters, nullable values

### Result
- Represents success/failure with error info
- `Ok(value)` - Success with value
- `Error(error)` - Failure with error details
- Use for: Operations that can fail

## Converting Between Types

### Option -> Result
```gleam
// Convert Option to Result with default error
option.to_result(my_option, "default error")

// Example:
Some(1) |> option.to_result("error") // -> Ok(1)
None |> option.to_result("error")    // -> Error("error")
```

### Result -> Option
```gleam
// Convert Result to Option (discards error info)
result.from_result(my_result)

// Example:
Ok(1) |> option.from_result    // -> Some(1)
Error("err") |> option.from_result  // -> None
```

## Common Type Mismatch Patterns & Solutions

### Pattern 1: Mixed Result/Option in Case Statements
```gleam
// ❌ Problem: Type mismatch
case some_result {
  Ok(value) -> Some(value)  // Returns Option
  Error(_) -> None         // Returns Option
}

// ✅ Solution: Consistent return types
case some_result {
  Ok(value) -> Ok(Some(value))  // Both return Result
  Error(e) -> Error(e)
}
```

### Pattern 2: Nested Options/Results
```gleam
// ❌ Problem: Deeply nested types
Some(Some(value))
Ok(Ok(value))

// ✅ Solution: Use flatten
option.flatten(Some(Some(value)))  // -> Some(value)
result.flatten(Ok(Ok(value)))      // -> Ok(value)
```

### Pattern 3: Working with Lists
```gleam
// ❌ Problem: List of mixed types
[Ok(1), Error("e"), Ok(2)]
[Some(1), None, Some(2)]

// ✅ Solution: Use partition or values
result.partition([Ok(1), Error("e")])  // -> #([1], ["e"])
option.values([Some(1), None, Some(2)]) // -> [1, 2]
```

## Best Practices

1. **Be Consistent**: Choose Result for functions that can fail, Option for optional values

2. **Type Annotations**: Add type annotations when pattern matching to help compiler:
```gleam
case my_value {
  Some(value) -> 
    case value {
      MyType(..) -> // Access fields here
    }
}
```

3. **Chain Operations**: Use `map`, `then`, and `try` for cleaner code:
```gleam
// Instead of nested case statements
result.map(my_result, fn(x) { x + 1 })
option.then(my_option, fn(x) { Some(x + 1) })
```

4. **Early Returns**: Handle None/Error cases early:
```gleam
case optional_value {
  None -> default_value
  Some(value) -> // Continue with main logic
}
```

## Common Functions

### Option
- `option.map`: Transform value inside Some
- `option.then`: Chain Option-returning functions
- `option.unwrap`: Get value with default
- `option.flatten`: Simplify nested Options

### Result
- `result.map`: Transform value inside Ok
- `result.try`: Chain Result-returning functions
- `result.unwrap`: Get value with default
- `result.flatten`: Simplify nested Results