
import UIKit


class PopUpGallery: UIView, UIGestureRecognizerDelegate{
    
    let gallery = UIScrollView()
    var photos : [UIImage]?
    var imView = UIImageView()
    var counter = 0
    
    override init(frame: CGRect){
        super.init(frame: frame)
        backgroundColor = .gray
        clipsToBounds = true
        layer.cornerRadius = 5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
//MARK: - version with UIImage
extension PopUpGallery{
    
    func configureImageGallery(){
        self.addSubview(imView)
        imView.pinObject(to: self)
        imView.backgroundColor = .black
        imView.clipsToBounds = true
        if let photosAr = photos{
            imView.image = photosAr[0]
            imView.contentMode = .scaleAspectFit
        }
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(sRight))
        swipeRight.direction = .right
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(sLeft))
        swipeLeft.direction = .left
        self.addGestureRecognizer(swipeRight)
        self.addGestureRecognizer(swipeLeft)
        print("loaded")
    }

    @objc func sRight(){ // after swiping right in gallery
        if let photosAr = photos{
            if (counter - 1) >= 0 {
                counter -= 1
                DispatchQueue.main.async{
                    self.imView.changeImageWithAnimation(image: photosAr[self.counter])
                    self.imView.setNeedsDisplay()
                }
            }
        }
        
    }
    @objc func sLeft(){ // after swiping left in gallery
        if let photosAr = photos{
            if (counter + 1) < photosAr.count{
                print(photosAr.count)
                counter += 1
                DispatchQueue.main.async{
                    self.imView.changeImageWithAnimation(image: photosAr[self.counter])
                    self.imView.setNeedsDisplay()
                }
            }
        }
    }
    
    
    
}
//MARK: - Gallery Animations
extension UIImageView{
    func changeImageWithAnimation(image: UIImage, animated: Bool = true) { // looking through array of images with animation
        let duration = animated ? 0.2 : 0.0
        UIView.transition(with: self, duration: duration, options: .transitionCrossDissolve, animations: {
            self.image = image
        }, completion: nil)
    }
}
//MARK: - Data from binded object to cell
extension PopUpGallery{
    func getCurrentPage() -> UIImage?{
        if let photosAr = photos{
            print("current page number: \(counter)")
            print(photosAr[counter])
            return photosAr[counter]//hardcoded heic is not working
        }
        print("error ocurred!")
        return nil
    }
}
