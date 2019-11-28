//
//  LivePhotoVC.swift
//  LivelyGIFs
//
//  Created by Xue Yu on 4/4/17.
//  Copyright © 2017 XueYu. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import MobileCoreServices

class LivePhotoVC: UIViewController {
    
    var livePhotoAsset: PHAsset?
    var photoView: PHLivePhotoView!
    var gifView: UIImageView!
    var gifURL: URL?
    @IBOutlet weak var exportShareButton: UIButton!
    @IBOutlet weak var gifSizeSegmentedControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gifSizeSegmentedControl.selectedSegmentIndex = 1
        
        photoView = PHLivePhotoView(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.width))
        photoView.contentMode = .scaleAspectFit
        
        self.view.addSubview(photoView)
        
        gifView = UIImageView(frame: CGRect.init(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.width))
        gifView.contentMode = .scaleAspectFit
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.photoView.center = self.view.center
        self.gifView.center = self.view.center
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
    }
    
    func configureView() {
        if let photoAsset = livePhotoAsset {
            PHImageManager.default().requestLivePhoto(for: photoAsset, targetSize: photoView.frame.size, contentMode: .aspectFit, options: nil, resultHandler: { (photo: PHLivePhoto?, info: [AnyHashable : Any]?) in
                
                if let livePhoto = photo{
                    self.photoView.livePhoto = livePhoto
                    self.photoView.startPlayback(with: .hint)
                    
                    if let photoLocation = photoAsset.location {
                        let geoCoder = CLGeocoder()
                        geoCoder.reverseGeocodeLocation(photoLocation, completionHandler: { (placemark: [CLPlacemark]?, error: Error?) in
                            if error == nil {
                                self.navigationItem.title = placemark?.first?.locality
                            }
                        })
                    }
                }
            })
        }
    }
    
    
    @IBAction func segmentedControlClicked(_ sender: UISegmentedControl) {
        exportShareButton.setTitle("Export GIF", for: .normal)
    }
    
    
    
    @IBAction func exportShareButton(_ sender: UIButton) {
        if exportShareButton.titleLabel?.text == "Export GIF" {
            
            let resources = PHAssetResource.assetResources(for: livePhotoAsset!)
            for resource in resources {
                if resource.type == .pairedVideo {
                    self.getMovieData(resource)
                    break
                }
            }
        } else {
            let activityVC = UIActivityViewController(activityItems: [gifURL!], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            self.present(activityVC, animated: true, completion: nil)
        }
        
    }
    
    
    func getMovieData(_ resource: PHAssetResource){
        
        let movieURL = URL(fileURLWithPath: (NSTemporaryDirectory()).appending("video.mov"))
        removeFileIfExists(fileURL: movieURL)

        
        PHAssetResourceManager.default().writeData(for: resource, toFile: movieURL as URL, options: nil) { (error) in
            if error != nil{
                print("Could not write video file")
            } else {
                DispatchQueue.main.async {
                    self.convertToGIF(movieURL)
                }
            }
        }
    }
    
    
    func convertToGIF(_ movieURL: URL){
        
        let movieAsset = AVURLAsset(url: movieURL as URL)
        
        // collect the needed parameters
        let duration = CMTimeGetSeconds(movieAsset.duration)
        let track = movieAsset.tracks(withMediaType: AVMediaType.video).first!
        let frameRate = track.nominalFrameRate
        
        gifURL = URL(fileURLWithPath: (NSTemporaryDirectory()).appending("file.gif"))
        removeFileIfExists(fileURL: gifURL!)
        
        var width  = 0
        
        switch gifSizeSegmentedControl.selectedSegmentIndex {
        case 0:
            width =  240
        case 1:
            width =  480
        case 2:
            width =  640
        default:
            width = 0
        }
  
        
        Regift.createGIFFromSource(movieURL as URL, destinationFileURL: gifURL, startTime: 0.0, duration: Float(duration), frameRate: Int(frameRate), loopCount: 0, width: width, height: width) {_ in
          
            exportShareButton.setTitle("Share", for: .normal)
            self.gifView.loadGif(url: gifURL!)
            self.photoView.removeFromSuperview()
            self.view.addSubview(gifView)
        }
        
    }
    

    
    func removeFileIfExists(fileURL : URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            }
            catch {
                print("Could not delete exist file so cannot write to it")
            }
        }
    }


}
