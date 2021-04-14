
import UIKit

protocol ReceiptCellActions{
    func deleteCellAndItsContent(cellNumber: Int)
    func renameAndSaveAsNewCell(cellNumber : Int, newName: String)
}

class ReceiptScanTableViewCell: UITableViewCell {
    
    var navControllerToPresent : UINavigationController? // just for presenting
    // creating uikit parts
    var scanImageView = UIImageView()
    var scanTitleLabel = UILabel()
    
    var chosen : Int?  // eventual property for choosing option after holding cell
    var arrayOfPhotos : [UIImage]? //all images of current cell
    
    var delegate : ReceiptCellActions?
    
    private var referenceToGesture : UIGestureRecognizer?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //adding parts of cell to subview of that view
        addSubview(scanImageView)
        addSubview(scanTitleLabel)
        configureCell() // setting up all of constrains
        configureHoldGestureRecognizer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - ConfigurationOfTableView
extension ReceiptScanTableViewCell{
    
    func configureCell(){
        configureImageView()
        configureTitleLabel()
        setImageConstrains()
        setTitleLabelConstrains()
    }
    
    func configureImageView(){
        scanImageView.layer.cornerRadius = 5
        scanImageView.clipsToBounds = true // allows to show radius
    }
    
    func configureTitleLabel(){
        scanTitleLabel.numberOfLines = 0
        scanTitleLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setImageConstrains(){
        scanImageView.translatesAutoresizingMaskIntoConstraints = false
        scanImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scanImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        scanImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        scanImageView.widthAnchor.constraint(equalTo: scanImageView.heightAnchor, multiplier: 2/3).isActive = true
    }
    
    func setTitleLabelConstrains(){
        scanTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scanTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        scanTitleLabel.leadingAnchor.constraint(equalTo: scanImageView.trailingAnchor, constant: 20).isActive = true
        scanTitleLabel.heightAnchor.constraint(equalToConstant: 35).isActive = true
        scanTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
    }
}

//MARK: - SettingUp cell, properties
extension ReceiptScanTableViewCell{
    
    func setCellProperties(scan: ReceiptScan){
        scanImageView.image = scan.scanImage[0] //first scan will always be set as minature
        scanTitleLabel.text = scan.title
    }
    
}
//MARK: - GestureRecognizer
extension ReceiptScanTableViewCell{
    
    func configureHoldGestureRecognizer(){
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(generateActionSheet))
        hold.delegate = self
        hold.minimumPressDuration = 0.5
        referenceToGesture = hold
        self.addGestureRecognizer(hold)
        
        print("configured hold option")
    }
    
}
//MARK: - Action sheet for tableView cells
extension ReceiptScanTableViewCell{
    
     @objc func generateActionSheet(){ // inside this class, to underline connection
        if let gesture = referenceToGesture{
            removeGestureRecognizer(gesture)
        }
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.warning)
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let rename = UIAlertAction(title: "Rename receipt", style: .default) { (rename) in
            let fb = UINotificationFeedbackGenerator()
            fb.notificationOccurred(.success)
            self.renameAlert()
        }
        let export = UIAlertAction(title: "Export whole receipt to gallery", style: .default) { (expert) in
            let fb = UINotificationFeedbackGenerator()
            fb.notificationOccurred(.success)
            self.exportReceiptScans()
        }
        let delete = UIAlertAction(title: "Delete receipt", style: .destructive) { (delete) in
            let fb = UINotificationFeedbackGenerator()
            fb.notificationOccurred(.warning)
            if let index = self.chosen{
                self.delegate?.deleteCellAndItsContent(cellNumber: index)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (cancel) in

        }
        actionSheet.addAction(rename)
        actionSheet.addAction(export)
        actionSheet.addAction(delete)
        actionSheet.addAction(cancel)

        self.navControllerToPresent?.present(actionSheet, animated: true, completion: configureHoldGestureRecognizer)
    }

    
    func renameAlert(){
        var txtField = UITextField()
        let renameAlert = UIAlertController(title: "Rename receipt", message: nil, preferredStyle: .alert)
        renameAlert.addTextField { (renameTextField) in
            renameTextField.placeholder = "DD:MM:YYYY"
            txtField = renameTextField
        }
        let action = UIAlertAction(title: "Ready", style: .default) { (action) in
            if let renamed = txtField.text, let cellNumber = self.chosen{
                if renamed == self.scanTitleLabel.text{
                    return
                }else{
                    self.scanTitleLabel.text = renamed
                    self.delegate?.renameAndSaveAsNewCell(cellNumber: cellNumber, newName: renamed)
                }
            }
        }
        renameAlert.addAction(action)
        navControllerToPresent?.present(renameAlert, animated: true, completion: nil)
    }
    
    func exportReceiptScans(){
        if let array = arrayOfPhotos{
            for index in 0..<array.count{
                NSLog("%d", index)
                UIImageWriteToSavedPhotosAlbum(array[index], self, nil, nil)

            }
        }
    }
    
}

  
