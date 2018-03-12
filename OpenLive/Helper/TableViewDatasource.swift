//
//  TableViewDatasource.swift
//  Streaming
//
//  Created by Sky Xu on 1/18/18.
//  Copyright © 2018 Sky Xu. All rights reserved.
//

import Foundation
import UIKit

typealias tableCellCallback = (UITableView, IndexPath) -> UITableViewCell

class TableViewDataSource<Item>: NSObject, UITableViewDataSource {
    
    var configureCell: tableCellCallback?
    var items: [Item]
    init(items: [Item]) {
        self.items = items
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(items.count)
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let configureCell = configureCell {
            print("okey \(configureCell)")
        } else {
            precondition(false, "You didn't pass a configurecell closure to configurecell")
        }
        
        return configureCell!(tableView, indexPath)
    }
    
}