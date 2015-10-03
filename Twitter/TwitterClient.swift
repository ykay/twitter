//
//  TwitterClient.swift
//  Twitter
//
//  Created by Yuichi Kuroda on 10/1/15.
//  Copyright © 2015 Yuichi Kuroda. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

private let twitterConsumerKey = "rCR1szO5RrohQDz3tAigPsXFJ"
private let twitterConsumerSecret = "kRaUPVtvjrF5HVOb5G4YaBwUyAI27pU9Un7bkjZKRWg2qZwnLr"
private let twitterBaseUrl = "https://api.twitter.com"

class TwitterClient: BDBOAuth1RequestOperationManager {
  
  static let sharedInstance = TwitterClient(baseURL: NSURL(string: twitterBaseUrl), consumerKey: twitterConsumerKey, consumerSecret: twitterConsumerSecret)
  
  var loginCompletion: ((User?, NSError?) -> Void)?
  
  func login(completion: (User?, NSError?) -> Void) {
    loginCompletion = completion
    
    // Remove access token from previous logged on session
    requestSerializer.removeAccessToken()
    fetchRequestTokenWithPath("oauth/request_token", method: "GET", callbackURL: NSURL(string: "cptwitterclient://oauth"), scope: nil,
      success: { (requestToken: BDBOAuth1Credential!) -> Void in
        print("Got the request token!")
        
        let authUrl = NSURL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(requestToken.token)")
        UIApplication.sharedApplication().openURL(authUrl!)
      },
      failure: { (error: NSError!) -> Void in
        print("Failed to get the request token")
        
        self.loginCompletion?(nil, error)
      }
    )
  }
  
  func openURL(url: NSURL) {
    fetchAccessTokenWithPath("oauth/access_token", method: "POST", requestToken: BDBOAuth1Credential(queryString: url.query!),
      success: { (accessToken: BDBOAuth1Credential!) -> Void in
        print("Got the access token!")
        
        self.requestSerializer.saveAccessToken(accessToken)
        
        self.GET("1.1/account/verify_credentials.json", parameters: nil,
          success: { (request: AFHTTPRequestOperation!, data: AnyObject!) -> Void in
            
            let user = User(data as! [String:AnyObject])
            print("user name: \(user.name)")
            
            self.loginCompletion?(user, nil)
          },
          failure: { (request: AFHTTPRequestOperation!, error: NSError!) -> Void in
            print("Failed to get user data")
            self.loginCompletion?(nil, error)
        })
        
        /*self.GET("1.1/statuses/home_timeline.json", parameters: nil,
          success: { (request: AFHTTPRequestOperation!, data: AnyObject!) -> Void in
            
            for tweet in Tweet.tweetsWithArray(data as! [AnyObject]) {
              print("Tweet: " + tweet.text)
            }
          },
          failure: { (request: AFHTTPRequestOperation!, error: NSError!) -> Void in
            print("Failed to get tweet data")
        })*/
      },
      failure: {
        (error: NSError!) -> Void in
        print("Failed to get the access token!")
        self.loginCompletion?(nil, error)
    })

  }
}