//
//  main.swift
//  critx
//
//  Created by Uchitel on 08.07.16.
//  Copyright © 2016 Uchitel. All rights reserved.
//

import Foundation
import WebKit

let inputUrl = Process.arguments[1]

var domain = "mityugin.com"
var htp = "http"
let slash = "://"
let timestamp = Int(NSDate().timeIntervalSince1970*100000)
let datestamp = "\(timestamp)"

if inputUrl.hasPrefix("https://") {
    htp="https"
}

var offset = htp.characters.count + slash.characters.count
domain = inputUrl.substring(from: inputUrl.index(inputUrl.startIndex, offsetBy: offset))

let url = htp+slash+domain
let homePath = "\(NSHomeDirectory())/Downloads/Web"
let dataPath = "\(homePath)/\(htp)"
let purlsPath = "\(homePath)/purls"
let ourlsPath = "\(homePath)/ourls"

func matchesForRegexInText(regex: String, text: String) -> [String] {
    do {
        let regex = try RegularExpression(pattern: regex, options: [.caseInsensitive])
        let range = NSMakeRange(0, text.characters.count)
        let results = regex.matches(in: text, options: [], range: range)
        let nsString = text as NSString
        let urls: [String] = results.map { result in
            return nsString.substring(with: result.range(at: 1))
        }
        return urls
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

let session = URLSession.shared
let request = URLRequest(url: URL(string: url)!)

let task = session.dataTask(with: request, completionHandler: {
    (data, response, error) -> Void in
    
    var usedEncoding =  String.Encoding.utf8// Some fallback value
    
    if let encodingName = response?.textEncodingName {
        
        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
        if encoding != kCFStringEncodingInvalidId {
            
            usedEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
            
        }
    }
    
    if let mydata = data {
    if let myString = String(data: mydata, encoding: usedEncoding) {
       
        if let attributedString = AttributedString(html: data!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: usedEncoding.rawValue], documentAttributes: nil) {
        
        var newString = attributedString.string

        newString = newString.replacingOccurrences(of: "\n", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: "\t", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: ". ", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: ", ", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: ")", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: "(", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: " -", with: " ", options:NSString.CompareOptions.literal, range: nil)
        newString = newString.replacingOccurrences(of: "- ", with: " ", options:NSString.CompareOptions.literal, range: nil)
        
        var wordArr = newString.components(separatedBy: " ")
        var newwordArr = [String]()
        var wordSet = Set<String>()
        
        for (index,var wordStr) in wordArr.enumerated() {
            
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.controlCharacters)
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.whitespacesAndNewlines)
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.symbols)

            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.decimalDigits)
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.punctuation)
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.decimalDigits)
            
            wordStr = wordStr.trimmingCharacters(
                in: NSCharacterSet.whitespacesAndNewlines)
            
            if wordStr.characters.count>3 {
                
                newwordArr.append(wordStr)
                wordSet.insert(wordStr)
            }

        }
        
        var newwordTup = [(String, Int)]()
        var count: Int
        
        for words in wordSet {
            
            count = 0
            for wordStr in newwordArr {
                if wordStr == words {
                    count += 1
                    
                }
            }
            if count > 1 {
                newwordTup.append((words, count))
            }
            
        }
        
        if newwordTup.count > 0 {
            
            newwordTup.sort(isOrderedBefore: { $0.1 == $1.1 ? $0.1 > $1.1 : $0.1 > $1.1 })
            var c = 10
            newwordArr = []
            
            if newwordTup.count < c {
                c = newwordTup.count - 1
            }
            
            newwordArr.append(domain)
            for n in 0...c {
                
                newwordArr.append(newwordTup[n].0)
                
                //print words
//                print(newwordArr[n])
            }
            
            //Create folder
            let fileManager = FileManager.default
            do
            {
                try fileManager.createDirectory(atPath: dataPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                print("Error while creating a folder.")
            }

            //Write words to file
            let stringRepresentation = newwordArr.joined(separator: ",")
            do {
                try stringRepresentation.write(toFile: "\(dataPath)/\(datestamp).txt", atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("error writing file")
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
            
        }
        
        
        
        let matches = matchesForRegexInText(regex: "href=\"([^\"]*?)\"", text: myString)
        var pageUrls: Set<String> = []
        var otherUrls: Set<String> = []
        
        for var matchStr in matches {
            if (matchStr.hasPrefix(url) || matchStr.hasPrefix("/")) && !(matchStr.hasSuffix(".png") || matchStr.hasSuffix(".jpg") || matchStr.hasSuffix(".ico")) && (matchStr != url) && (matchStr != url+"/") && (matchStr != "/") {
                if matchStr.hasPrefix("/") {
                    matchStr = url+matchStr
                }
                pageUrls.insert(matchStr)
                
            } else {
                if !matchStr.hasPrefix(url) && !matchStr.hasPrefix("/") && matchStr.hasPrefix("http") && !(matchStr.hasSuffix(".png") || matchStr.hasSuffix(".jpg") || matchStr.hasSuffix(".ico")) {
                   otherUrls.insert(matchStr)
                }
            }
            
            
        }
            
            //Create folders
            let fileManager = FileManager.default
            do
            {
                try fileManager.createDirectory(atPath: ourlsPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                print("Error while creating a folder.")
            }
            
            do
            {
                try fileManager.createDirectory(atPath: purlsPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error as NSError
            {
                print("Error while creating a folder.")
            }
            
            //Write urls to file
            var stringRepresentation = pageUrls.joined(separator: ",")
            do {
                try stringRepresentation.write(toFile: "\(purlsPath)/\(datestamp).txt", atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("error writing purls file")
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
            stringRepresentation = otherUrls.joined(separator: ",")
            do {
                try stringRepresentation.write(toFile: "\(ourlsPath)/\(datestamp).txt", atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("error writing ourls file")
                // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            }
        // print URLs
//        for matchStr in pageUrls {
//            print(matchStr)
//        }
//        for matchStr in otherUrls {
//            print(matchStr)
//        }
        
        } else {
            print("failed to convert string")
        }
    } else {
        print("failed to decode data")
    }
    } else {
        print("no such url \(url)")
    }
    exit(EXIT_SUCCESS)
})

// Running URLSession
task.resume()

// Terminate execution with CTRL+C
RunLoop.main.run()
