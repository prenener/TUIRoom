//
//  RaiseHandApplicationListView.swift
//  TUIRoomKit
//
//  Created by 唐佳宁 on 2023/1/13.
//  Copyright © 2023 Tencent. All rights reserved.
//

import Foundation

class RaiseHandApplicationListView: UIView {
    let viewModel: RaiseHandApplicationListViewModel
    var attendeeList: [UserModel]
    var searchArray: [UserModel] = []
    
    let searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = .searchMemberText
        controller.searchBar.setBackgroundImage(UIColor(0x1B1E26).trans2Image(), for: .top, barMetrics: .default)
        controller.obscuresBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        return controller
    }()
    
    let allAgreeButton : UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(.agreeAllText, for: .normal)
        button.setTitleColor(UIColor(0xADB6CC), for: .normal)
        button.backgroundColor = UIColor(0x292D38)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.adjustsImageWhenHighlighted = false
        let userRole = EngineManager.shared.store.currentUser.userRole
        let roomInfo = EngineManager.shared.store.roomInfo
        button.isHidden = (userRole != .roomOwner)
        button.isSelected = !roomInfo.enableAudio
        return button
    }()
    
    let inviteMemberButton: UIButton = {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(.inviteMembersText, for: .normal)
        button.setTitleColor(UIColor(0xADB6CC), for: .normal)
        button.backgroundColor = UIColor(0x292D38)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.adjustsImageWhenHighlighted = false
        let userRole = EngineManager.shared.store.currentUser.userRole
        let roomInfo = EngineManager.shared.store.roomInfo
        button.isHidden = (userRole != .roomOwner)
        button.isSelected = !roomInfo.enableVideo
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "room_back_white", in: tuiRoomKitBundle(), compatibleWith: nil), for: .normal)
        button.setTitleColor(UIColor(0xD1D9EC), for: .normal)
        button.setTitle(.raiseHandApplyText, for: .normal)
        return button
    }()
    
    lazy var applyTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(0x1B1E26)
        tableView.register(UserListCell.self, forCellReuseIdentifier: "RaiseHandCell")
        tableView.tableHeaderView = searchController.searchBar
        return tableView
    }()
    
    init(viewModel: RaiseHandApplicationListViewModel) {
        self.viewModel = viewModel
        self.attendeeList = viewModel.attendeeList
        super.init(frame: .zero)
        EngineEventCenter.shared.subscribeUIEvent(key: .TUIRoomKitService_RenewSeatList, responder: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isViewReady: Bool = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        backgroundColor = UIColor(0x1B1E26)
        guard !isViewReady else { return }
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        isViewReady = true
    }
    
    func setNavigationLeftBarButton() {
        RoomRouter.shared.currentViewController()?.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        RoomRouter.shared.currentViewController()?.navigationItem.hidesSearchBarWhenScrolling = false
        RoomRouter.shared.currentViewController()?.navigationController?.navigationBar.isTranslucent = false
        RoomRouter.shared.currentViewController()?.navigationController?.navigationBar.backgroundColor = UIColor(0x1B1E26)
    }
    
    func constructViewHierarchy() {
        addSubview(applyTableView)
        addSubview(allAgreeButton)
        addSubview(inviteMemberButton)
    }
    
    func activateConstraints() {
        applyTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.bottom.equalToSuperview()
        }
        allAgreeButton.snp.makeConstraints { make in
            make.trailing.equalTo(snp.centerX).offset(-10)
            make.bottom.equalToSuperview().offset(-40 - kDeviceSafeBottomHeight)
            make.height.equalTo(50)
            make.leading.equalToSuperview().offset(30)
        }
        inviteMemberButton.snp.remakeConstraints { make in
            make.leading.equalTo(snp.centerX).offset(10)
            make.bottom.equalTo(allAgreeButton)
            make.height.equalTo(50)
            make.trailing.equalToSuperview().offset(-30)
        }
    }
    
    func bindInteraction() {
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        backButton.addTarget(self, action: #selector(backAction(sender:)), for: .touchUpInside)
        allAgreeButton.addTarget(self, action: #selector(allAgreeStageAction(sender:)), for: .touchUpInside)
        inviteMemberButton.addTarget(self, action: #selector(inviteMemberAction(sender:)), for: .touchUpInside)
    }
    
    @objc func backAction(sender: UIButton) {
        viewModel.backAction(sender: sender)
    }
    
    @objc func allAgreeStageAction(sender: UIButton) {
        viewModel.allAgreeStageAction(sender: sender, view: self)
    }
    
    @objc func inviteMemberAction(sender: UIButton) {
        viewModel.inviteMemberAction(sender: sender, view: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchController.searchBar.endEditing(true)
        attendeeList = viewModel.attendeeList
        applyTableView.reloadData()
    }
    
    deinit {
        EngineEventCenter.shared.unsubscribeUIEvent(key: .TUIRoomKitService_RenewSeatList, responder: self)
        debugPrint("deinit \(self)")
    }
}

extension RaiseHandApplicationListView: UISearchControllerDelegate, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchArray = viewModel.attendeeList.filter({ model -> Bool in
            if let searchText = searchController.searchBar.text {
                return (model.userName == searchText)
            } else {
                return false
            }
        })
        attendeeList = searchArray
        applyTableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        attendeeList = viewModel.attendeeList
        applyTableView.reloadData()
    }
}

extension RaiseHandApplicationListView: UITableViewDataSource {
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attendeeList.count
    }
}

extension RaiseHandApplicationListView: UITableViewDelegate {
    internal func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attendeeModel = attendeeList[indexPath.row]
        let cell = ApplyTableCell(attendeeModel: attendeeModel, viewModel: viewModel)
        cell.selectionStyle = .none
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchController.searchBar.endEditing(true)
    }
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68.scale375()
    }
}

extension RaiseHandApplicationListView: RoomKitUIEventResponder {
    func onNotifyUIEvent(key: EngineEventCenter.RoomUIEvent, Object: Any?, info: [AnyHashable : Any]?) {
        if key == .TUIRoomKitService_RenewSeatList {
            attendeeList = EngineManager.shared.store.inviteSeatList
            applyTableView.reloadData()
        }
    }
}

class ApplyTableCell: UITableViewCell {
    let attendeeModel: UserModel
    let viewModel: RaiseHandApplicationListViewModel
    
    let avatarImageView: UIImageView = {
        let img = UIImageView()
        img.layer.cornerRadius = 20
        img.layer.masksToBounds = true
        return img
    }()
    
    let userLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(0xD1D9EC)
        label.backgroundColor = UIColor.clear
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()
    
    let muteAudioButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "room_mic_on", in: tuiRoomKitBundle(), compatibleWith: nil), for: .normal)
        button.setImage(UIImage(named: "room_mic_off", in: tuiRoomKitBundle(), compatibleWith: nil), for: .selected)
        return button
    }()
    
    let muteVideoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "room_camera_on", in: tuiRoomKitBundle(), compatibleWith: nil), for: .normal)
        button.setImage(UIImage(named: "room_camera_off", in: tuiRoomKitBundle(), compatibleWith: nil), for: .selected)
        return button
    }()
    
    let agreeStageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor(0x0565FA)
        button.setTitle(.agreeSeatText, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.clipsToBounds = true
        return button
    }()
    
    let disagreeStageButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .red
        button.setTitle(.disagreeSeatText, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.clipsToBounds = true
        return button
    }()
    
    let downLineView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(0x2A2D38)
        return view
    }()
    
    init(attendeeModel: UserModel ,viewModel: RaiseHandApplicationListViewModel) {
        self.attendeeModel = attendeeModel
        self.viewModel = viewModel
        super.init(style: .default, reuseIdentifier: "UserListCell")
    }
    private var isViewReady: Bool = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else { return }
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        isViewReady = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func constructViewHierarchy() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(userLabel)
        contentView.addSubview(muteAudioButton)
        contentView.addSubview(muteVideoButton)
        contentView.addSubview(agreeStageButton)
        contentView.addSubview(disagreeStageButton)
        contentView.addSubview(downLineView)
    }
    
    func activateConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        muteVideoButton.snp.makeConstraints { make in
            make.width.height.equalTo(36)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(self.avatarImageView)
        }
        muteAudioButton.snp.makeConstraints { make in
            make.width.height.equalTo(36)
            make.right.equalTo(self.muteVideoButton.snp.left).offset(-12)
            make.centerY.equalTo(self.avatarImageView)
        }
        disagreeStageButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(self.avatarImageView)
            make.width.height.equalTo(80.scale375())
            make.height.equalTo(24.scale375())
        }
        agreeStageButton.snp.makeConstraints { make in
            make.right.equalTo(disagreeStageButton.snp.left).offset(-5)
            make.centerY.equalTo(disagreeStageButton)
            make.width.height.equalTo(80.scale375())
            make.height.equalTo(24.scale375())
        }
        userLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.width.equalTo(150.scale375())
            make.height.equalTo(48)
        }
        downLineView.snp.makeConstraints { make in
            make.left.equalTo(userLabel)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.3)
        }
    }
    
    func bindInteraction() {
        backgroundColor = UIColor(0x1B1E26)
        setupViewState(item: attendeeModel)
        agreeStageButton.addTarget(self, action: #selector(agreeStageAction(sender:)), for: .touchUpInside)
        disagreeStageButton.addTarget(self, action: #selector(disagreeStageAction(sender:)), for: .touchUpInside)
    }
    
    func setupViewState(item: UserModel) {
        let placeholder = UIImage(named: "room_default_user", in: tuiRoomKitBundle(), compatibleWith: nil)
        if let url = URL(string: item.avatarUrl) {
            avatarImageView.sd_setImage(with: url, placeholderImage: placeholder)
        } else {
            avatarImageView.image = placeholder
        }
        if item.userRole == .roomOwner {
            userLabel.text = item.userName + "(" + .meText + ")"
        } else {
            userLabel.text = item.userName
        }
        muteAudioButton.isSelected = !item.hasAudioStream
        muteVideoButton.isSelected = !item.hasVideoStream
        if item.isOnSeat {
            agreeStageButton.isHidden = true
            disagreeStageButton.isHidden = true
            muteAudioButton.isHidden = false
            muteVideoButton.isHidden = false
        } else {
            agreeStageButton.isHidden = false
            disagreeStageButton.isHidden = false
            muteAudioButton.isHidden = true
            muteVideoButton.isHidden = true
        }
    }
    
    @objc func agreeStageAction(sender: UIButton) {
        viewModel.agreeStageAction(sender: sender, isAgree: true, userId: attendeeModel.userId)
    }
    
    @objc func disagreeStageAction(sender: UIButton) {
        viewModel.agreeStageAction(sender: sender, isAgree: false, userId: attendeeModel.userId)
    }
    
    deinit {
        debugPrint("deinit \(self)")
    }
}

private extension String {
    static let raiseHandApplyText = localized("TUIRoom.raise.hand.apply")
    static let searchMemberText = localized("TUIRoom.search.meeting.member")
    static let agreeAllText = localized("TUIRoom.agree.all")
    static let inviteMembersText = localized("TUIRoom.invite.members")
    static let agreeSeatText = localized("TUIRoom.agree.seat")
    static let disagreeSeatText = localized("TUIRoom.disagree.seat")
    static let meText = localized("TUIRoom.me")
}