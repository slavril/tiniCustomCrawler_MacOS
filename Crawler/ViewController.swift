//
//  ViewController.swift
//  Crawler
//
//  Created by Son Dang on 5/16/17.
//  Copyright © 2017 Son Dang. All rights reserved.
//

import Cocoa

import Foundation

class ViewController: NSViewController {
    @IBOutlet weak var textField: NSTextField?
    var content: String = "";
    
    // Input your parameters here
    let startUrl = URL(string: "http://trangvangvietnam.com/cateprovinces/245670/du_h%E1%BB%8Dc_-_t%C6%B0_v%E1%BA%A5n_v%C3%A0_d%E1%BB%8Bch_v%E1%BB%A5_%E1%BB%9F_t%E1%BA%A1i_tp._h%E1%BB%93_ch%C3%AD_minh_(tphcm).html")!
    let wordToSearch = "mailto:"
    let maximumPagesToVisit = 10
    
    // Crawler Parameters
    let semaphore = DispatchSemaphore(value: 0)
    var visitedPages: Set<URL> = []
    var pagesToVisit: Set<URL> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        pagesToVisit.insert(startUrl)
        
        
        crawl()
        semaphore.wait()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // Crawler Core
    func crawl() {
        guard visitedPages.count <= maximumPagesToVisit else {
            printScreen(content: "Reached max number of pages to visit")
            semaphore.signal()
            return
        }
        guard let pageToVisit = pagesToVisit.popFirst() else {
            printScreen(content: "Reach limit page");
            semaphore.signal()
            return
        }
        if visitedPages.contains(pageToVisit) {
            crawl()
        } else {
            visit(page: pageToVisit)
        }
    }
    
    func visit(page url: URL) {
        visitedPages.insert(url)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { self.crawl() }
            guard
                let data = data,
                error == nil,
                let document = String(data: data, encoding: .utf8) else { return }
            self.parse(document: document, url: url)
        }
        
        printScreen(content: "Visiting page: \(url)");
        task.resume()
    }
    
    func parse(document: String, url: URL) {
        func find(word: String) {
            if document.contains(word) {
                printScreen(content: word);
            }
        }
        
        func collectLinks() -> [URL] {
            func getMatches(pattern: String, text: String) -> [String] {
                // used to remove the 'href="' & '"' from the matches
                func trim(url: String) -> String {
                    return String(url.characters.dropLast()).substring(from: url.index(url.startIndex, offsetBy: "href=\"".characters.count))
                }
                
                let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex.matches(in: text, options: [.reportCompletion], range: NSRange(location: 0, length: text.characters.count))
                return matches.map { trim(url: (text as NSString).substring(with: $0.range)) }
            }
            
            let pattern = "href=\"(http://.*?|https://.*?)\""
            let matches = getMatches(pattern: pattern, text: document)
            return matches.flatMap { URL(string: $0) }
        }
        
        find(word: wordToSearch)
        collectLinks().forEach { pagesToVisit.insert($0) }
    }
    
    private func printScreen(content: String) {
        self.content = self.content + content + "\n"
        textField?.stringValue = self.content
    }
}

