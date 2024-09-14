//
//  appUtil.swift
//  trtcScenesDemo
//
//  Created by xcoderliu on 12/24/19.
//  Copyright © 2019 xcoderliu. All rights reserved.
//

import UIKit
import ImSDK_Plus
import TUIRoomKit
import RTCRoomEngine

// IMSDK APNS ID
#if DEBUG
    let timSdkBusiId: UInt32 = 18_069
#else
    let timSdkBusiId: UInt32 = 18_070
#endif

class AppUtils: NSObject {
    var roomId: String?
    weak var navigationController: UINavigationController?
    @objc static let shared = AppUtils()
    private override init() {
        super.init()
        ConferenceSession.sharedInstance.addObserver(observer: self)
    }
    
    @objc var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    @objc var curUserId: String {
        #if NOT_LOGIN
            return ""
        #else
            return V2TIMManager.sharedInstance()?.getLoginUser() ?? ""
        #endif
    }
    
    func showConferenceMainViewController(roomId: String) {
        let conferenceViewController = ConferenceMainViewController()
        let params = JoinConferenceParams(roomId: roomId)
        params.isOpenMicrophone = true
        params.isOpenCamera = false
        conferenceViewController.setJoinConferenceParams(params: params)
        navigationController?.pushViewController(conferenceViewController, animated: true)
    }
    
    func showConferenceOptionsViewController(nav: UINavigationController?) {
        guard ProfileManager.shared.curUserID() != nil else {
            debugPrint("not login")
            return
        }
        let prepareViewController = ConferenceOptionsViewController()
        navigationController = nav
        navigationController?.pushViewController(prepareViewController, animated: false)
        guard let roomId = roomId else { return }
        showConferenceMainViewController(roomId: roomId)
        self.roomId = nil
    }
}

extension AppUtils: ConferenceObserver {
    func onConferenceStarted(roomInfo: TUIRoomInfo, error: TUIError, message: String) {
        if error != .success {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func onConferenceJoined(roomInfo: TUIRoomInfo, error: TUIError, message: String) {
        if error != .success {
            navigationController?.popViewController(animated: true)
        }
    }
}
