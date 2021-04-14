
import UIKit
import VisionKit
import CoreData

class ReceiptListVC: UIViewController {
  
    var arrayOfReceipts : [ReceiptScan] = [] // array that stores objects that we can interact with, during runtime
    
    //MARK: - view and UI
    var receiptListTableView = UITableView() // creating tableview that will contain receipts
    
    let addNewButton = UIButton(type: .custom) // button that can add new scan
    
    private var tempReceiptObj = ReceiptScan() // temp object to store object on which we actually are working on
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext // persistent container of core data
    
    
    //MARK: - popUpGallery
    let dismissButtonNavBar = UIBarButtonItem(image: UIImage(systemName: K.returnBarButtonItem), style: .plain, target: self, action: #selector(dismissButtonPressed))
    
    var popUpGallery = PopUpGallery() // gallery for presenting scans
    
    //MARK: - Tracking Progress
    
    let blur : UIVisualEffectView = {
        let effect = UIBlurEffect(style: .light)
        let v = UIVisualEffectView(effect: effect)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
   //MARK: - Core Data
    
    var docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] //URL to document directory

    var arrayTakenFromCD = [ReceiptLight]() // here we will fetch array from db
    

    //MARK: - didLoads
    override func viewDidLoad() {
        //ORDER of views
        //navBar - 1
        //tableView - 2
        //button - 3
        super.viewDidLoad()
        
        // core data
        loadData() //core data must be first
        decodingDataAndLoadingToWorkingArray()
        // views
        configureNavBar()
        configureReceiptListTableView()
        configureAddNewButton()
        //tests
        //tests()
    }
    
}
//MARK: - ReceiptListTablView, functions
extension ReceiptListVC: UITableViewDelegate, UITableViewDataSource{
    
    func configureReceiptListTableView(){
        view.addSubview(receiptListTableView) //must be added to view to work properly
        setReceiptListTableViewDelegate()
        tableViewSetHeight() //set rowHeight
        tableViewRegisterCells()
        tableViewSetConstrains()
        
    }
    
    func setReceiptListTableViewDelegate(){ // setting delegates, for table view interaction and data source
        receiptListTableView.delegate = self
        receiptListTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfReceipts.count  //how many cells
    }
    
    //to show cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.receiptCellIdentifier) as! ReceiptScanTableViewCell // to get access to it
        cell.setCellProperties(scan: arrayOfReceipts[indexPath.row])
        cell.navControllerToPresent = self.navigationController
        cell.chosen = indexPath.row // to give ability of deleting
        cell.delegate = self
        cell.arrayOfPhotos = arrayOfReceipts[indexPath.row].scanImage
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.item)
        popUpGallery.photos = arrayOfReceipts[indexPath.item].scanImage
        configureAndRunPopUpGallery()//here we will show whole array of scans that we made
        configureNavBarTitle(selectedTitle: arrayOfReceipts[indexPath.item].title) //nav bar gets title of current scan name
    }
    
    
    func tableViewSetHeight(){
        receiptListTableView.rowHeight = 80 //TODO hardcoded for now
    }
    
    func tableViewSetConstrains(){
        receiptListTableView.pinObject(to: view)
    }
    
    func tableViewRegisterCells(){
        receiptListTableView.register(ReceiptScanTableViewCell.self, forCellReuseIdentifier: K.receiptCellIdentifier)
    }
    
    func reload(){
        DispatchQueue.main.async{
            self.receiptListTableView.reloadData()
        }
    }
    
    
}
//MARK: - Setting up UI and its functionality
extension ReceiptListVC{
    
    func configureNavBar(){
        title = "Your Receipts" // navigation bar title (Default one)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barTintColor = .black
    }
    
    func configureNavBarReturnButton(){
        let dismissButtonNavBar = UIBarButtonItem(image: UIImage(systemName: K.returnBarButtonItem), style: .plain, target: self, action: #selector(dismissButtonPressed))
        dismissButtonNavBar.tintColor = .white
        self.navigationItem.leftBarButtonItem = dismissButtonNavBar
    }
    
    func configureNavBarExportPageButton(){
        let exportButtonNavBar = UIBarButtonItem(image: UIImage(systemName: K.exportBarButtonItem), style: .plain, target: self, action: #selector(exportCurrentPage))
        exportButtonNavBar.tintColor = .white
        self.navigationItem.rightBarButtonItem = exportButtonNavBar
    }
    
    func configureNavBarTitle(selectedTitle: String){
        title = selectedTitle
    }
    
    func backToNormalNavBarTitle(){
        title = "Your Receipts"
    }
    
    func configureAddNewButton(){
        addNewButton.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        addNewButton.layer.cornerRadius = addNewButton.bounds.height * (1/2)
        addNewButton.backgroundColor = .clear
        addNewButton.setBackgroundImage(UIImage(named: "addButton"), for: .normal)
        addNewButton.addTarget(self, action: #selector(addNewButtonPressed), for: .touchUpInside)
        addNewButton.clipsToBounds = true
        view.addSubview(addNewButton)
        addNewButtonConstrains()
    }
    
    func addNewButtonConstrains(){

        addNewButton.translatesAutoresizingMaskIntoConstraints = false
        addNewButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        addNewButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        addNewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        addNewButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        
    }
    
    @objc func addNewButtonPressed(){
        configureScannerView() // configure and open documentView (present, dismiss) giving ability to make scan(s)
    }
     
}
//MARK: - VisionKit DocumentView
extension ReceiptListVC :  VNDocumentCameraViewControllerDelegate{
    func configureScannerView(){
        let scanner = VNDocumentCameraViewController()
        
        scanner.delegate = self
        self.present(scanner, animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        
        var scanArray : [UIImage] = [UIImage]()
        
        for page in 0..<scan.pageCount{ // pages are indexed from 0
            let image = scan.imageOfPage(at: page)
            scanArray.append(image)
        }
        tempReceiptObj.scanImage = scanArray // replacing UIImage array for new one
        
        controller.dismiss(animated: true, completion: changeNameOfLastScanThatWasMade) // after finished scanning, trigger changes
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        receiptListTableView.reloadData()
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}
//MARK: - Alerts
extension ReceiptListVC{
    func changeNameOfLastScanThatWasMade(){
        var alertTextField = UITextField()
        
        let alert = UIAlertController(title: "Add new Receipt", message: "You can set name of newly created Receipt", preferredStyle: .alert)
        alert.addTextField { (setNameTextField) in
            setNameTextField.placeholder = "DD:MM:YYYY"
            alertTextField = setNameTextField
        }
        let action = UIAlertAction(title: "Ready", style: .default) { (action) in

            for index in 0..<self.arrayOfReceipts.count{     // iterating through array, to find if there are receipts with the same title
                if self.arrayOfReceipts[index].title == alertTextField.text!{
                    let tmp = "\(alertTextField.text!)(\(self.getCurrentTimeAsString()))" // if there is, edit text that was provided by the user
                    alertTextField.text = tmp
                    //TODO: check once again if there is no any duplicates, after change
                }
            }
            self.assignNameWithoutWhiteSpaces(with: alertTextField.text!)
            self.arrayOfReceipts.append(self.tempReceiptObj) // adding temporary object to array
            
            self.savePhotoAndStoreURLwithTitle() // saving to struct
            self.loadData()
            DispatchQueue.main.async{
                self.receiptListTableView.reloadData()
            }
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    
}
//MARK: - PopUpGallery
extension ReceiptListVC {
    
    func goBackToMainView() {
        backToNormalNavBarTitle()
        popUpGallery.counter = 0  
        UIView.animate(withDuration: 0.5) {
            self.blur.alpha = 0
            self.popUpGallery.alpha = 0
            self.popUpGallery.transform = CGAffineTransform(scaleX: 1, y: 1)
        } completion: { (bool) in
            print("deleted gallery from superview ")
            self.popUpGallery.removeFromSuperview()
        }

        self.blur.alpha = 0
        self.popUpGallery.alpha = 0
        self.popUpGallery.transform = CGAffineTransform.identity
    }
    
    
    func configureAndRunPopUpGallery(){
        configuteBlurEffect()
        configureNavBarReturnButton()
        configureNavBarExportPageButton()
        view.addSubview(popUpGallery)
        popUpGallery.translatesAutoresizingMaskIntoConstraints = false
        popUpGallery.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant:  30).isActive = true
        popUpGallery.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popUpGallery.heightAnchor.constraint(equalToConstant: view.frame.height - 150).isActive = true
        popUpGallery.widthAnchor.constraint(equalToConstant: view.frame.width - 50).isActive = true
        popUpGallery.configureImageGallery()
        popUpGallery.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        popUpGallery.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.blur.alpha = 1
            self.popUpGallery.alpha = 1
            self.popUpGallery.transform = CGAffineTransform.identity
        }
    }
    
    func configuteBlurEffect(){
        view.addSubview(blur)
        blur.pinObject(to: view) //stick blur effect to borders of view
        blur.alpha = 0
    }
    
    @objc func dismissButtonPressed(){
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        NSLog("pressed return to main view")
        goBackToMainView()
    }
    
    @objc func exportCurrentPage(){
        if let pageToExport = popUpGallery.getCurrentPage(){
            NSLog("Exported chosen scan successfully")
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
            UIImageWriteToSavedPhotosAlbum(pageToExport, self, nil, nil)
        }else{
            NSLog("Failed to export chosen scan")
        }
    }
}
//MARK: - Saving/Loading photos and titles
extension ReceiptListVC{
    
    func savePhotoAndStoreURLwithTitle(){
        var temp = [String]()
            
        for index in 0 ..< tempReceiptObj.scanImage.count{
            let url = docDir.appendingPathComponent("\(tempReceiptObj.title)\(index).png") // here we will save image data
            
            if let data = tempReceiptObj.scanImage[index].pngData(){
                do{
                    try data.write(to: url)
                    print("LAST PATH COMPONENT ->\(url.lastPathComponent)")
                    temp.append(url.lastPathComponent) // relative!!
                    
                }catch{
                    print("sometheing went wrong with saving data to url. Error message: \(error)")
                    return
                }
            }
        }
        
        var listOfURLS : String = "" // container for encoded array of string
        do{
            let data = try JSONSerialization.data(withJSONObject: temp, options: .fragmentsAllowed) // encoding array of strings to json
            listOfURLS = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))! // pass encoded array and make it String
            
        }catch{
            print(error)
            return
        }
        
        let newReceiptLight = ReceiptLight(context: context)
        newReceiptLight.listOfUrlsToPNG = listOfURLS
        newReceiptLight.title = tempReceiptObj.title
        
        saveContext()
    }
    
    func saveContext(){
        do{
            try context.save()
        }catch{
            print(error)
        }
    }

    func loadData(){
        
        let request: NSFetchRequest<ReceiptLight> = ReceiptLight.fetchRequest()
        
        do{
            arrayTakenFromCD = try context.fetch(request) // fetch data from core data
            NSLog("fetched!")
        }catch{
            print(error)
        }
        
    }
    
    func decodingDataAndLoadingToWorkingArray(){
        
        for index in 0..<arrayTakenFromCD.count{
            do{
                let data = Data(arrayTakenFromCD[index].listOfUrlsToPNG!.utf8) //really important during decoding

                if let decodedArray  = try JSONSerialization.jsonObject(with: data, options: []) as? [String]{
                    
                    var arrayOfImagesToAdd = [UIImage]() // temporaty image array, that we will pass to Receipt Scan object

                    for x in 0..<decodedArray.count{  // run loop as many times as many photos realtive urls were saved to one array
                        
                            let fullPathToLastLocation = "\(docDir)\(decodedArray[x])" // making one url, from relative path saved to core data, and acctual path to documents dir
                            let url = URL(string: fullPathToLastLocation)
                            print("NORMAL \(url!)")
                            print("RELATIVE \(url!.relativePath)")
                            if let img = UIImage(contentsOfFile: url!.relativePath){
                                print("Img to add -> \(img)")
                                arrayOfImagesToAdd.append(img)
                            }else{
                                print("no image!")
                            }
                    }
                    let receiptToAdd = ReceiptScan(title: arrayTakenFromCD[index].title!, scanImage: arrayOfImagesToAdd) // object that we add do interact with it
                    arrayOfReceipts.append(receiptToAdd)
                }
            }catch{
                print(error)
            }
        }
    }
}
//MARK: - Getting Data, Deleting Data
extension ReceiptListVC : ReceiptCellActions{
    func renameAndSaveAsNewCell(cellNumber: Int, newName: String) {
        
        //1 save scans from cell
        let tempScansContainer = arrayOfReceipts[cellNumber].scanImage
        //2 delete cell, and delete it from context
        deleteCellAndItsContent(cellNumber: cellNumber)
        //3 add new that contains scans to context and current runtime array
        tempReceiptObj.scanImage = tempScansContainer
        assignNameWithoutWhiteSpaces(with: newName) // replace whitespaces with -
        arrayOfReceipts.append(tempReceiptObj)
        savePhotoAndStoreURLwithTitle()
        //4 reload tableview
        DispatchQueue.main.async {
            self.receiptListTableView.reloadData()
        }
    }
    
    
    func getCurrentTimeAsString() -> String{
        let date = Date()
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        let y = parts.year!
        let m = parts.month!
        let d = parts.day!
        let h = parts.hour!
        let min = parts.minute!
        let s = parts.second!
        let fullActualDateAsString : String = "\(h):\(min):\(s) \(d).\(m).\(y)"
        return fullActualDateAsString
    }
    
    
    func deleteCellAndItsContent(cellNumber: Int){
        
        if arrayOfReceipts.count == arrayTakenFromCD.count{ // it must be the same count
            deletePhotosFromDocDirOfCell(cellNumber: cellNumber)
            arrayOfReceipts.remove(at: cellNumber) // remove chosen cell in temporary to use area
            context.delete(arrayTakenFromCD[cellNumber])// remove from core data
            arrayTakenFromCD.remove(at: cellNumber) // remove also from temporary fetched array to make possible to user one again delete right thing
            saveContext()
        }else{
            print("Impossible to happen")
            fatalError() // can't happen if we are trying to delete something
        }
        reload()
    }
    
    func deletePhotosFromDocDirOfCell(cellNumber: Int){ // releasing memory (sandbox), by deleting photos form document directory (after user decides to delete cell)
        for i in 0..<arrayOfReceipts[cellNumber].scanImage.count{
            let url = docDir.appendingPathComponent("\(arrayOfReceipts[cellNumber].title)\(i).png")
            print(url)
            do{
                try FileManager.default.removeItem(at: url)
            }catch{
                print("There was a problem with deleting file from url: \(error)")
            }
        }
    }
}
extension ReceiptListVC{
    func assignNameWithoutWhiteSpaces(with s: String){
        let ifThereAreWhitespacesReplaceThem = s.replacingOccurrences(of: " ", with: "-")
        self.tempReceiptObj.title = ifThereAreWhitespacesReplaceThem
    }
}

//MARK: - tests
extension ReceiptListVC{
    
    func tests(){
        print(docDir)
        let array : [UIImage] = [UIImage(named: K.testPhotoForCell)!, UIImage(named: K.testPhotoForCell)!] //adding placeholder for real scan
        tempReceiptObj = ReceiptScan(title: "hello", scanImage:array)
        savePhotoAndStoreURLwithTitle()
    }
}

