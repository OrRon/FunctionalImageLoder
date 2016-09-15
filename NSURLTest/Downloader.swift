//
//  Downloader.swift
//  NSURLTest
//
//  Created by Or on 12/09/2016.
//  Copyright © 2016 Or. All rights reserved.
//

import UIKit

typealias   CacheTable = Dictionary<String,NSURL>
typealias   Key = String

struct Cache {
    
    static var table = CacheTable()
    
    static func get(key:Key,cacheTable:CacheTable)->(NSData?) {
        guard let url = cacheTable[key] else { return nil }
        return NSData(contentsOfURL:url)
    }
    
    static func  set(key:Key,data:NSData) {
        var cacheTable = table
        if cacheTable[key] == nil {
            if let randomURL = getRandomPath() {
                cacheTable[key] = randomURL
                data.writeToURL(randomURL, atomically: true)
            }
        }
        table = cacheTable
    }
    
    static func getRandomPath()->(NSURL?) {
        let tmpDir = NSURL(fileURLWithPath: NSTemporaryDirectory()) as NSURL!
        let fileName = NSUUID().UUIDString
        let fileURL = tmpDir.URLByAppendingPathComponent(fileName)
        return fileURL
    }
}


struct Downloader<A> {
    
    let parse:(_:(NSData)->(A?))
    
    func downloadURL(url:NSURL,complition:(_:A?)->()) {
        if let data = Cache.get(url.absoluteString,cacheTable: Cache.table) {
            complition(self.parse(data))
        } else {
            NSURLSession.sharedSession().dataTaskWithURL(url) {
                data, _, _ in
                if let data = data {
                    dispatch_async(dispatch_get_main_queue(), {
                        complition(self.parse(data))
                        Cache.set(url.absoluteString,data: data)
                    })
                }
            }.resume()
        }
    }
}

struct imageProvider {
    static var sharedInstance = imageProvider()
    
    var downloader:Downloader<UIImage> {
        get {
            return Downloader<UIImage> { data in
                return UIImage(data:data)
            }
        }
    }

}

extension UIImageView {
    
    func load(url:NSURL) {
        self.image = nil
        imageProvider.sharedInstance.downloader.downloadURL(url) { (image) in
            if let image = image {
                self.image = image
            }
        }
    }
    
    func load(String string:String) {
        if let url = NSURL(string: string) {
            load(url)
        }
        
    }
}




