//
//  PhotoCollectionVC.swift
//  LivelyGIFs
//
//  Created by Xue Yu on 4/4/17.
//  Copyright © 2017 XueYu. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"

class PhotoCollectionVC: UICollectionViewController {
    
    var livePhotoAssets: PHFetchResult<PHAsset>?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        PHPhotoLibrary.requestAuthorization { (status:PHAuthorizationStatus) in
            switch status {
                case .authorized:
                    self.fetchPhotos()
                default:
                    self.showNoPhotoAccessAlert()
            }
        }

    }
    

    
    func fetchPhotos() {
        
        let sortDesciptor = NSSortDescriptor(key: "creationDate", ascending:false)
        let predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoLive.rawValue)
        
        let options = PHFetchOptions()
        
        options.sortDescriptors = [sortDesciptor]
        options.predicate = predicate
        
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.livePhotoAssets = PHAsset.fetchAssets(with: options)
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }
    
    
    func showNoPhotoAccessAlert() {
        let alert = UIAlertController(title: "No Photo Access Permission", message: "Please grant this App access your photos in Settings -- > Privacy", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler:{ (action: UIAlertAction) in
            let url = URL(string: UIApplication.openSettingsURLString)
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            return
        }))
        
        self.present(alert, animated: true, completion: nil)
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let numberOfItems = livePhotoAssets?.count {
            return numberOfItems
        } else {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        if let asset = livePhotoAssets?[indexPath.row]{
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            
            let targetSize = CGSize(width: 100, height: 100)
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (image: UIImage?, info: [AnyHashable : Any]?) in
                cell.photoImageView.image = image
            })
        }
        
        return cell
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = collectionView?.indexPathsForSelectedItems?.first {
            let photoVC = segue.destination as! LivePhotoVC
            photoVC.livePhotoAsset = livePhotoAssets?[indexPath.item]
        }
    }
}
