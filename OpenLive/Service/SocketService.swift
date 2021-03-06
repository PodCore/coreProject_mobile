//
//  SocketService.swift
//  OpenLive
//
//  Created by Sky Xu on 2/8/18.
//  Copyright © 2018 Agora. All rights reserved.
//

import Foundation
import SocketIO
import UIKit

class SocketService: NSObject {
    static let instance = SocketService()
    
    let manager = SocketManager(
        socketURL: URL(string: Config.serverUrl)!,
        config: [.log(true), .compress, .reconnects(true)]
    )
    
//    only initialize socket when we call this service instance so we can fix manager property not initalized before runtime issue
   lazy var socket: SocketIOClient = manager.defaultSocket
    
    func establishConnection() {
        socket.connect()
    }
    
    func observeIfConnected(completion: @escaping NormalCallback){
//        socket.on(clientEvent: .disconnect, callback: completion)
        socket.on(clientEvent: .connect, callback: completion)
    }
    
    func closeConnection() {
        socket.disconnect()
    }
//    exit out of room
    func exitRoom(roomname: String, owner: String, completion: @escaping (Bool) -> ()) {
        socket.emit("close_room", ["name": roomname, "owner": owner])
        completion(true)
    }
    
    func addChannel(id: String, name: String, owner: String, topic: String, viewCount: Int, likes: Int, viewers: [String], image: String, location: Location, completion: @escaping (Bool) -> ()) {
        let locationDict = location.toDict()
        let room = Room(dict: ["name": name as Any,
                               "id": id as Any,
                               "owner": owner as Any,
                               "topic": topic as Any,
                               "viewCount": viewCount as Any,
                               "likes": likes as Any,
                               "viewers": viewers as [String],
                               "image": image as String,
                               "location": locationDict as [String: Any]])
        socket.emit("create_room", room.toDict())

        completion(true)
    }
    
    func joinChannel(username: String, owner: String, completion: @escaping (Bool) -> ()) {
        let data = ["username": username, "owner": owner]
        socket.emit("join_room", data)
        
        completion(true)
    }
    
//    // MARK: get data from service once socket connected
    func getChannel(completion: @escaping (Bool, [Room]) -> ()) {
//        listening for event
            self.socket.emit("get_rooms")
            socket.on("get_rooms") {(data, ack) in
                guard let json = data[0] as? [Any]
                   else {return}
                // convert json into array of Room
                let rooms = json.map{Room(dict:$0 as! [String : Any])}
                
        completion(true, rooms)
        }
    }
    
    //  MARK: get new rooms that just got created
    func getNewChannel(completion: @escaping (Bool, Room) -> ()) {
        socket.on("new_room") {(data, ack) in
            guard let json = data[0] as? Any else { return }
            let room = Room(dict: json as! [String: Any])
            completion(true, room)
        }
    }
    
    // MARK:  Follow Host
    func followHost(owner: String, completion: @escaping (Bool) -> ()) {
        let following = Following(dict: ["username": "sky" as AnyObject, "followingName": "james" as AnyObject])
        self.socket.emit("new_follower", following.toDict())
        completion(true)
    }
    
    // MARK: live comment in watchRoom
    func liveComment(comment: String, owner: String, commenter: String, roomId: String, completion: @escaping (Bool) -> ()) {
        let comment = Comment(dict: ["comment": comment as Any,
                                     "owner": owner as Any,
                                     "commenter": commenter as Any,
                                     "roomId": roomId as Any])
        self.socket.emit("comment", comment.toDict())
        completion(true)
    }
    
//    get all comments from socket
    func getComments(completion: @escaping (Bool, NewComment) -> ()) {
        socket.on("comment") { (data, ack) in
            guard let json = data[0] as? Any else { return }
            let newComment = NewComment(dict: json as! [String : Any])
            completion(true, newComment)
        }
    }
    //    send "emoji": send back "owner", "gifter", get back gifter(a list of gifter?)"giferName", emojiNum, : "emojiNUm":"frequency of emoji")
    func sendEmoji(emojier: String, emojiNum: String, owner: String, completion: @escaping (Bool) -> Void) {
        let emoji = ["emojiNum": emojiNum as Any,
                     "emojier": emojier as Any,
                     "owner": owner as Any]
        self.socket.emit("emoji", emoji)
        completion(true)
    }
    
    func getEmoji(completion: @escaping (Bool, String, Int, String) -> Void) {
        socket.on("emoji") { (data, ack) in
            guard let json = data[0] as? Any else { return }
            let emoji = Emoji(dict: json as! [String: Any])
            let emojier = emoji.emojier
            let emojiNum = emoji.emojiNum
            let emojiGram = emoji.emojiGram as! [String: Any]
            let frequency = emojiGram[emojiNum] as! Int
            
            completion(true, emojier, frequency, emojiNum)
        }
    }
    // send   "upvote" : send back "owner", "upvoter": get back number of upvotes("likes")
    func sendUpvote(owner: String, upvoter: String, completion: @escaping (Bool) -> Void) {
        let upvoteInfo = ["owner": owner as Any,
                          "upvoter": upvoter as Any]
        self.socket.emit("upvote", upvoteInfo)
        completion(true)
    }
    
//    get likes
    func getUpvote(completion: @escaping (Bool, Upvote) -> Void) {
        socket.on("upvote") { (data, ack) in
            guard let json = data[0] as? Any else { return }
            let upvote = Upvote(dict: json as! [String: Any])
            completion(true, upvote)
        }
    }
    
    func getFollowees(username: String, completion: @escaping (Bool, [Followee]) -> ()) {
        socket.emit("following", username)
        socket.on("following") { (data, ack) in
            guard let json = data[0] as? [Any]
                else {return}
            // convert json into array of Room
            let followees = json.map{Followee(dict:$0 as! [String : Any])}
            completion(true, followees)
        }
    }
    
    func getUser(username: String, completion: @escaping (Bool, User) -> ()) {
        socket.emit("get_user", username)
        socket.on("get_user") { (data, ack) in
            guard let json = data[0] as? Any else { return }
            print("PRINTINGJSON\(json)")
            let user = User(dict: json as! [String : Any])
            completion(true, user)
        }
    }
    
}

