//
//  OverlayViewController.swift
//  OpenLive
//
//  Created by Sky Xu on 2/16/18.
//  Copyright © 2018 Agora. All rights reserved.
//

import UIKit
import SocketIO

class OverlayViewController: UIViewController {
    
    @IBOutlet weak var commentInputContainer: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var upvoteButton: DesignableButton!
    @IBOutlet weak var likes: UILabel!
    @IBOutlet weak var emojiCount: UILabel!
    @IBOutlet weak var emojiButton: DesignableButton!
    @IBOutlet weak var waveView: WaveEmitterView!
    var roomId: String?
    var comments: [String] = [] {
        didSet {
            self.tableViewDatasource.items = comments
            self.tableView.dataSource = self.tableViewDatasource
            self.tableView.reloadData()
        }
    }// call didset so that we can update datasource to tableview when it's changed?
    var commenter: String?
    var commentData = [NewComment]()
    let tableViewDatasource = TableViewDataSource(items: [])
    
    @IBAction func commentTapped(_ sender: UIButton) {
        SocketService.instance.liveComment(comment: textField.text!, owner: "sky", commenter: "sky2", roomId: roomId!) { (success) in
            if success {
                print("successfully commented")
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.contentInset.top = tableView.bounds.height
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewDatasource.items = comments
        self.tableView.dataSource = self.tableViewDatasource
        
        //  wait 1 s for socket to work and automtically roll comments
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick(_:)), userInfo: nil, repeats: true)
        
        SocketService.instance.getComments { (success, data) in
            self.comments.append(data.comment)
            self.tableView.reloadData()
        }
        
        tableViewDatasource.configureCell = {(tableView, indexPath) -> UITableViewCell in
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as! CommentCell
            if self.comments.count > 0 {
                cell.selfComment = self.comments[indexPath.row]
            }
            return cell
        }
        
        SocketService.instance.getUpvote { (success, likes) in
            if success {
                let heart = UIImage(named: "heart")
                self.waveView.emitImage(heart!)
                self.likes.text = "\(likes.likes)"
                
            }
        }
        
        SocketService.instance.getEmoji { (success, emojier, emojiCount)  in
            if success {
                self.emojiCount.text = "\(emojiCount)"
                let emoji = UIImage(named: "gift-1")!
                self.waveView.emitImage(emoji)
            }
        }
    }
    
    @IBAction func emojiTapped(_ sender: DesignableButton) {
        print(sender.tag)
        SocketService.instance.sendEmoji(emojier: "tony", emojiNum: "\(sender.tag)", owner: "sky") { (success) in
            if success {
                print("emoji sent success")
            }
        }
    }
    
    @IBAction func upvoteTapped(_ sender: DesignableButton) {
        SocketService.instance.sendUpvote(owner: "sky", upvoter: "tony") { (success) in
            if success {
                print("upvote success")
            }
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        textField.resignFirstResponder()
    }
    
//    for automatically scrolling tableView of comments
    @objc func tick(_ time: Timer) {
        guard comments.count > 0 else { return }
        if tableView.contentSize.height > tableView.bounds.height {
            tableView.contentInset.top = 0
        }
        tableView.scrollToRow(at: IndexPath(row: comments.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
    }
}
