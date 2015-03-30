//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let YepChangeProfilePhotoNotification = "YepChangeProfilePhotoNotification"

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileCollectionView: UICollectionView!

    let skillRanckCellIdentifier = "SkillRankCell"
    let headerCellIdentifier = "ProfileHeaderCell"
    let footerCellIdentifier = "ProfileFooterCell"
    let sectionHeaderIdentifier = "ProfileSectionHeaderReusableView"
    let sectionFooterIdentifier = "ProfileSectionFooterReusableView"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.profileCollectionView.bounds)
        }()
    lazy var sectionLeftEdgeInset: CGFloat = { return 20 }()
    lazy var sectionRightEdgeInset: CGFloat = { return 20 }()
    lazy var sectionBottomEdgeInset: CGFloat = { return 20 }()

    lazy var cellWidth: CGFloat = {
        return (self.collectionViewWidth - (self.sectionLeftEdgeInset + self.sectionRightEdgeInset)) / 3
        }()
    let cellHeight: CGFloat = 40
    let avatarAspectRatio: CGFloat = 12.0 / 16.0

    let introductionText = "I would like to learn Design or Speech, I can teach you iOS Dev in return. 😃"

    let masterSkills = [
        ["skill":"iOS Dev", "rank":3],
        ["skill":"Linux", "rank":2],
        ["skill":"Cook", "rank":1],
    ]

    let learningSkills = [
        ["skill":"Design", "rank":1],
        ["skill":"Speech", "rank":0],
    ]
    
    var imagePicker = UIImagePickerController()

    lazy var footerCellHeight: CGFloat = {
        let attributes = [NSFontAttributeName: profileIntroductionLabelFont]
        let labelWidth = self.collectionViewWidth - (profileIntroductionLabelLeadingSpaceToContainer + profileIntroductionLabelTrailingSpaceToContainer)
        let rect = self.introductionText.boundingRectWithSize(CGSize(width: labelWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes:attributes, context:nil)
        return ceil(rect.height)
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollectionView.registerNib(UINib(nibName: skillRanckCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillRanckCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: headerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: headerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: footerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: footerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: sectionHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderIdentifier)
        profileCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: sectionFooterIdentifier)

        profileCollectionView.alwaysBounceVertical = true
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.BlackTranslucent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)!
        ]
        
        self.navigationController?.navigationBar.titleTextAttributes = textAttributes

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeProfileImage", name: YepChangeProfilePhotoNotification, object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func changeProfileImage() {
        println("Do Change")
        
        var sheet: UIActionSheet = UIActionSheet();
        let title: String = "Photo Source"
        sheet.title  = title
        sheet.delegate = self
        sheet.addButtonWithTitle("Album");
        sheet.addButtonWithTitle("Camera");
        sheet.addButtonWithTitle("Cancel");
        sheet.cancelButtonIndex = 2;
        sheet.showInView(self.view);

    }

}

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate{
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        s3PublicUploadParams(failureHandler: nil) { s3UploadParams in
            println("s3UploadParams: \(s3UploadParams)")
            var imageData = UIImagePNGRepresentation(image);
            //let form = token["options"] as! JSONDictionary
            //uploadFileToAWSS3(filePath: filePath, dataForm: form)
            uploadFileToS3(filePath: nil, fileData: imageData, mimetype: "image/png", s3UploadParams: s3UploadParams, completion: { (result, error) in
                if (result) {
                    let newAvatarURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"
                    updateUserInfo(nickname: nil, avatar_url: newAvatarURLString, username: nil, latitude: nil, longitude: nil, completion: { result in
                        YepUserDefaults.setAvatarURLString(newAvatarURLString)
                        println("Update user info \(result)")
                    })
                    
                }
            })
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 0) {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
                
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
                imagePicker.allowsEditing = false
                
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }else if (buttonIndex == 1) {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
                imagePicker.allowsEditing = false
                
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
    }


    enum ProfileSection: Int {
        case Header = 0
        case Master
        case Learning
        case Footer
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {

        case ProfileSection.Header.rawValue:
            return 1

        case ProfileSection.Master.rawValue:
            return 3

        case ProfileSection.Learning.rawValue:
            return 2

        case ProfileSection.Footer.rawValue:
            return 1

        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(headerCellIdentifier, forIndexPath: indexPath) as! ProfileHeaderCell

            cell.nameLabel.text = YepUserDefaults.nickname()

            return cell

        case ProfileSection.Master.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell

            cell.rankView.barColor = UIColor.skillMasterColor()

            let skillInfo = masterSkills[indexPath.row % masterSkills.count]
            cell.skillLabel.text = skillInfo["skill"] as? String
            cell.rankView.rank = skillInfo["rank"] as! Int

            return cell

        case ProfileSection.Learning.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell

            cell.rankView.barColor = UIColor.skillLearningColor()

            let skillInfo = learningSkills[indexPath.row % learningSkills.count]
            cell.skillLabel.text = skillInfo["skill"] as? String
            cell.rankView.rank = skillInfo["rank"] as! Int

            return cell

        case ProfileSection.Footer.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell

            cell.introductionLabel.text = introductionText

            return cell

        default:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell

            return cell
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! ProfileSectionHeaderReusableView

            switch indexPath.section {

            case ProfileSection.Header.rawValue:
                header.titleLabel.text = ""

            case ProfileSection.Master.rawValue:
                header.titleLabel.text = NSLocalizedString("Master", comment: "")

            case ProfileSection.Learning.rawValue:
                header.titleLabel.text = NSLocalizedString("Learning", comment: "")

            case ProfileSection.Footer.rawValue:
                header.titleLabel.text = NSLocalizedString("Introduction", comment: "")

            default:
                header.titleLabel.text = ""
            }

            return header

        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionFooterIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
            return footer
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch section {

        case ProfileSection.Header.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

        case ProfileSection.Master.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case ProfileSection.Learning.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case ProfileSection.Footer.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

        default:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:
            return CGSizeMake(collectionViewWidth, collectionViewWidth * avatarAspectRatio)

        case ProfileSection.Master.rawValue:
            return CGSizeMake(cellWidth, cellHeight)

        case ProfileSection.Learning.rawValue:
            return CGSizeMake(cellWidth, cellHeight)

        case ProfileSection.Footer.rawValue:
            return CGSizeMake(collectionViewWidth, footerCellHeight)

        default:
            return CGSizeZero
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        if section == ProfileSection.Header.rawValue {
            return CGSizeMake(collectionViewWidth, 0)

        } else {
            return CGSizeMake(collectionViewWidth, cellHeight)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeMake(collectionViewWidth, 0)
    }
}


