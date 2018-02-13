//
//  NFXJson2Codable.swift
//  netfox_ios
//
//  Created by Ștefan Suciu on 2/13/18.
//  Copyright © 2018 kasketis. All rights reserved.
//

#if os(OSX)
import Foundation
    
extension String {
    
    func uppercaseFirstLetter() -> String {
        let paranthesisCount = components(separatedBy: "]").count - 1
        let stringWithoutParanthesis = dropFirst(paranthesisCount)
        
        return String(repeating: "[", count: paranthesisCount) + stringWithoutParanthesis.capitalized
    }
    
    func lowercaseFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    var camelCasedString: String {
        return components(separatedBy: CharacterSet(charactersIn: "_ ")).map{ $0.lowercased().uppercaseFirstLetter() }.joined()
    }
    
    var singular: String {
        let paranthesisCount = components(separatedBy: "]").count - 1
        let stringWithoutParanthesis = dropLast(paranthesisCount)
        
        if stringWithoutParanthesis.last == "s" {
            return stringWithoutParanthesis.dropLast() + String(repeating: "]", count: paranthesisCount)
        }
        
        return self
    }
}




class Parser<T> {
    
    func canParse(_ value: Any) -> Bool {
        return value is T
    }
    
    func getPropertyType() -> String {
        return "\(T.self)"
    }
}

extension Parser where T == [String: Any] {
    
    func parse(_ value: Any) -> T {
        return value as! T
    }
    
    func getPropertyType(name: String) -> String {
        return "\(name)"
    }
}

extension Parser where T == [Any] {
    
    func parse(_ value: Any) -> T {
        return value as! T
    }
}



class CodableClass: CustomStringConvertible {
    
    var className: String
    var properties: [(String, String)] = []
    
    init(className: String) {
        self.className = className
    }
    
    func addProperty(name: String, type: String) {
        properties.append((name, type))
    }
    
    var description: String {
        var str = "class \(className.camelCasedString.singular): Codable {\n\n"
        str += properties.map{ "\tvar \($0.0.camelCasedString.lowercaseFirstLetter()): \($0.1.camelCasedString.singular)!" }.joined(separator: "\n")
        str += "\n\n\tenum CodingKeys: String, CodingKey {\n"
        str += properties.map{"\t\tcase \($0.0.camelCasedString.lowercaseFirstLetter()) = \"\($0.0)\""}.joined(separator: "\n")
        str += "\n\t}"
        str += "\n}\n\n"
        return str
    }
}



public class Json2Codable {
    
    private let intParser = Parser<Int>()
    private let stringParser = Parser<String>()
    private let doubleParser = Parser<Double>()
    private let dictionaryParser = Parser<[String: Any]>()
    private let arrayParser = Parser<[Any]>()
    
    private var codableClasses: [CodableClass] = []
    
    func convertToCodable(name: String, from dictionary: [String: Any]) -> CodableClass {
        let codableClass = getCodableClass(name: name)
        
        dictionary.keys.forEach { key in
            codableClass.addProperty(
                name: key,
                type: convertToProperty(key: key, value: dictionary[key]!)
            )
        }
        
        return codableClass
    }
    
    private func convertToProperty(key: String, value: Any) -> String {
        if intParser.canParse(value) {
            return intParser.getPropertyType()
        } else if doubleParser.canParse(value) {
            return doubleParser.getPropertyType()
        } else if stringParser.canParse(value) {
            return stringParser.getPropertyType()
        } else if dictionaryParser.canParse(value) {
            let _ = convertToCodable(name: key, from: dictionaryParser.parse(value))
            return dictionaryParser.getPropertyType(name: key)
        } else if arrayParser.canParse(value) {
            return "[\(convertToProperty(key: key, value: arrayParser.parse(value).first!))]"
        }
        
        return ""
    }
    
    private func getCodableClass(name: String) -> CodableClass {
        var codableClass: CodableClass
        
        if let foundClass = codableClasses.first(where: { $0.className == name }) {
            codableClass = foundClass
        } else {
            codableClass = CodableClass(className: name)
            codableClasses.append(codableClass)
        }
        
        return codableClass
    }
    
    func getResourceName(from url: String?) -> String {
        guard let url = url else {
            return "ClassName"
        }
        
        var components = url.split(separator: "/")
        if let _ = Int(components.last ?? "") {
            components = Array(components.dropLast())
        }
        
        return String(components.last ?? "").singular
    }
    
    func printClasses() -> String {
        return codableClasses.map{ $0.description }.reduce("", +)
    }
}
#endif
