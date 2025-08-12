//
//  JSONPathParser.swift
//  ZenDevToolkit
//
//  JSONPath query parser and executor for extracting values from JSON
//

import Foundation

enum JSONPathError: LocalizedError {
    case invalidPath(String)
    case invalidJSON
    case noResults
    case unsupportedOperation(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidPath(let path):
            return "Invalid JSONPath: \(path)"
        case .invalidJSON:
            return "Invalid JSON data"
        case .noResults:
            return "No results found"
        case .unsupportedOperation(let op):
            return "Unsupported operation: \(op)"
        }
    }
}

class JSONPathParser {
    
    // Parse and execute JSONPath query
    static func query(json: String, path: String) throws -> [Any] {
        // Parse JSON string to object
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            throw JSONPathError.invalidJSON
        }
        
        // Clean and validate path
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else {
            throw JSONPathError.invalidPath("Path cannot be empty")
        }
        
        // Execute query based on path type
        return try executeQuery(on: jsonObject, path: cleanPath)
    }
    
    private static func executeQuery(on object: Any, path: String) throws -> [Any] {
        // Handle root selector
        if path == "$" {
            return [object]
        }
        
        // Parse path components
        let components = try parsePath(path)
        var results: [Any] = [object]
        
        for component in components {
            var newResults: [Any] = []
            
            for current in results {
                let matches = try processComponent(current, component: component)
                newResults.append(contentsOf: matches)
            }
            
            results = newResults
            if results.isEmpty {
                break
            }
        }
        
        return results
    }
    
    private static func parsePath(_ path: String) throws -> [PathComponent] {
        var components: [PathComponent] = []
        var remaining = path
        
        // Remove leading $ if present
        if remaining.hasPrefix("$") {
            remaining = String(remaining.dropFirst())
        }
        
        while !remaining.isEmpty {
            // Skip leading dots
            if remaining.hasPrefix(".") {
                remaining = String(remaining.dropFirst())
                
                // Handle recursive descent (..)
                if remaining.hasPrefix(".") {
                    remaining = String(remaining.dropFirst())
                    
                    // Get the next identifier or bracket expression
                    if let nextComponent = extractNextComponent(from: &remaining) {
                        components.append(.recursiveDescent(nextComponent))
                    }
                    continue
                }
            }
            
            // Handle bracket notation [...]
            if remaining.hasPrefix("[") {
                let bracket = extractBracketContent(from: &remaining)
                
                // Check for array index
                if let index = Int(bracket) {
                    components.append(.index(index))
                }
                // Check for wildcard
                else if bracket == "*" {
                    components.append(.wildcard)
                }
                // Check for slice notation
                else if bracket.contains(":") {
                    let parts = bracket.split(separator: ":")
                    let start = parts.count > 0 && !parts[0].isEmpty ? Int(parts[0]) : nil
                    let end = parts.count > 1 && !parts[1].isEmpty ? Int(parts[1]) : nil
                    components.append(.slice(start: start, end: end))
                }
                // Check for filter expression
                else if bracket.hasPrefix("?") {
                    let filter = String(bracket.dropFirst())
                    components.append(.filter(filter))
                }
                // Treat as property name in quotes
                else if bracket.hasPrefix("'") || bracket.hasPrefix("\"") {
                    let propertyName = bracket
                        .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    components.append(.property(propertyName))
                } else {
                    components.append(.property(bracket))
                }
            }
            // Handle property name
            else {
                let property = extractPropertyName(from: &remaining)
                if property == "*" {
                    components.append(.wildcard)
                } else if !property.isEmpty {
                    components.append(.property(property))
                }
            }
        }
        
        return components
    }
    
    private static func extractNextComponent(from path: inout String) -> PathComponent? {
        // Handle bracket notation after ..
        if path.hasPrefix("[") {
            let bracket = extractBracketContent(from: &path)
            if bracket == "*" {
                return .wildcard
            } else {
                return .property(bracket)
            }
        }
        
        // Handle property name after ..
        let property = extractPropertyName(from: &path)
        if property == "*" {
            return .wildcard
        } else if !property.isEmpty {
            return .property(property)
        }
        
        return nil
    }
    
    private static func extractBracketContent(from path: inout String) -> String {
        guard path.hasPrefix("[") else { return "" }
        path = String(path.dropFirst()) // Remove [
        
        var content = ""
        var inQuotes = false
        var quoteChar: Character?
        
        for char in path {
            if !inQuotes && char == "]" {
                path = String(path.dropFirst(content.count + 1)) // Remove content and ]
                break
            }
            
            if char == "'" || char == "\"" {
                if !inQuotes {
                    inQuotes = true
                    quoteChar = char
                } else if char == quoteChar {
                    inQuotes = false
                }
            }
            
            content.append(char)
        }
        
        return content
    }
    
    private static func extractPropertyName(from path: inout String) -> String {
        var property = ""
        
        for char in path {
            if char == "." || char == "[" {
                break
            }
            property.append(char)
        }
        
        path = String(path.dropFirst(property.count))
        return property
    }
    
    private static func processComponent(_ object: Any, component: PathComponent) throws -> [Any] {
        switch component {
        case .property(let name):
            if let dict = object as? [String: Any] {
                if let value = dict[name] {
                    return [value]
                }
            }
            
        case .index(let idx):
            if let array = object as? [Any] {
                let index = idx >= 0 ? idx : array.count + idx
                if index >= 0 && index < array.count {
                    return [array[index]]
                }
            }
            
        case .wildcard:
            if let dict = object as? [String: Any] {
                return Array(dict.values)
            } else if let array = object as? [Any] {
                return array
            }
            
        case .slice(let start, let end):
            if let array = object as? [Any] {
                let startIdx = start ?? 0
                let endIdx = end ?? array.count
                let normalizedStart = max(0, startIdx >= 0 ? startIdx : array.count + startIdx)
                let normalizedEnd = min(array.count, endIdx >= 0 ? endIdx : array.count + endIdx)
                
                if normalizedStart < normalizedEnd {
                    return Array(array[normalizedStart..<normalizedEnd])
                }
            }
            
        case .recursiveDescent(let subComponent):
            var results: [Any] = []
            
            // First, try to apply the component to current object
            results.append(contentsOf: try processComponent(object, component: subComponent))
            
            // Then recursively search all descendants
            results.append(contentsOf: recursiveSearch(in: object, for: subComponent))
            
            return results
            
        case .filter(let expression):
            // Basic filter support for common expressions
            if let array = object as? [Any] {
                return try filterArray(array, expression: expression)
            }
        }
        
        return []
    }
    
    private static func recursiveSearch(in object: Any, for component: PathComponent) -> [Any] {
        var results: [Any] = []
        
        if let dict = object as? [String: Any] {
            for value in dict.values {
                // Try to apply component to each value
                if let matches = try? processComponent(value, component: component) {
                    results.append(contentsOf: matches)
                }
                // Recurse into nested structures
                results.append(contentsOf: recursiveSearch(in: value, for: component))
            }
        } else if let array = object as? [Any] {
            for item in array {
                // Try to apply component to each item
                if let matches = try? processComponent(item, component: component) {
                    results.append(contentsOf: matches)
                }
                // Recurse into nested structures
                results.append(contentsOf: recursiveSearch(in: item, for: component))
            }
        }
        
        return results
    }
    
    private static func filterArray(_ array: [Any], expression: String) throws -> [Any] {
        // Parse basic filter expressions like @.price < 10
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Support @.property operator value format
        if trimmed.hasPrefix("@.") {
            let parts = trimmed.dropFirst(2).components(separatedBy: CharacterSet(charactersIn: " <>!="))
                .filter { !$0.isEmpty }
            
            guard parts.count >= 1 else {
                throw JSONPathError.unsupportedOperation("Invalid filter: \(expression)")
            }
            
            let property = parts[0]
            
            // Find operator
            var op = ""
            var foundOp = false
            for char in trimmed.dropFirst(2 + property.count) {
                if "<=>=!=<>".contains(char) {
                    op.append(char)
                    foundOp = true
                } else if foundOp {
                    break
                }
            }
            
            // Get value after operator
            let valueStr = trimmed
                .dropFirst(2 + property.count)
                .drop(while: { " <=>=!=<>".contains($0) })
                .trimmingCharacters(in: .whitespaces)
            
            return array.filter { item in
                guard let dict = item as? [String: Any],
                      let propValue = dict[property] else {
                    return false
                }
                
                return evaluateComparison(propValue, operator: op, value: valueStr)
            }
        }
        
        throw JSONPathError.unsupportedOperation("Complex filters not yet supported")
    }
    
    private static func evaluateComparison(_ left: Any, operator op: String, value: String) -> Bool {
        // Try to parse value as number
        if let rightNum = Double(value) {
            guard let leftNum = doubleValue(from: left) else { return false }
            
            switch op {
            case "<": return leftNum < rightNum
            case "<=": return leftNum <= rightNum
            case ">": return leftNum > rightNum
            case ">=": return leftNum >= rightNum
            case "==", "=": return leftNum == rightNum
            case "!=": return leftNum != rightNum
            default: return false
            }
        }
        
        // String comparison
        let leftStr = String(describing: left)
        let rightStr = value.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
        
        switch op {
        case "==", "=": return leftStr == rightStr
        case "!=": return leftStr != rightStr
        default: return false
        }
    }
    
    private static func doubleValue(from: Any) -> Double? {
        if let num = from as? Double {
            return num
        } else if let num = from as? Int {
            return Double(num)
        } else if let str = from as? String {
            return Double(str)
        }
        return nil
    }
    
    // Format results as JSON string
    static func formatResults(_ results: [Any]) -> String {
        if results.isEmpty {
            return "No results found"
        }
        
        if results.count == 1 {
            return formatValue(results[0])
        }
        
        // Format as JSON array
        do {
            let data = try JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            // Fallback to simple string representation
            return results.map { formatValue($0) }.joined(separator: "\n")
        }
    }
    
    private static func formatValue(_ value: Any) -> String {
        if let str = value as? String {
            return "\"\(str)\""
        } else if let _ = value as? [String: Any], 
                  let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) {
            return String(data: data, encoding: .utf8) ?? String(describing: value)
        } else if let _ = value as? [Any],
                  let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) {
            return String(data: data, encoding: .utf8) ?? String(describing: value)
        }
        return String(describing: value)
    }
}

// Path component types
private indirect enum PathComponent {
    case property(String)
    case index(Int)
    case wildcard
    case slice(start: Int?, end: Int?)
    case recursiveDescent(PathComponent)
    case filter(String)
}