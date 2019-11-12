//
//  ViewController.swift
//  Project 10 - Names To Faces
//
//  Created by Sean Williams on 15/10/2019.
//  Copyright © 2019 Sean Williams. All rights reserved.
//
import LocalAuthentication
import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var people = [Person]()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        
        let notificationCenter = NotificationCenter()
        notificationCenter.addObserver(self, selector: #selector(save), name: UIApplication.willResignActiveNotification, object: nil)
        
        authenticateUser()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authenticateUser()
    }

    
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authentication required to load saved data."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self?.loadDataFromUserDefaults()
                    } else {
                        // Error
                        let ac = UIAlertController(title: "FACE ID Failed", message: "You could not be identified.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                            if let password = KeychainWrapper.standard.string(forKey: "Password") {
                                self?.passwordAuthenticate(password: password)
                            } else {
                                self?.passwordAuthenticate(password: nil)
                            }
                        }))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // No biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
    
    func passwordAuthenticate(password: String?) {
        let ac = UIAlertController(title: "Enter Password", message: "If you are a new user, please create a password.", preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            guard let text = ac.textFields?[0].text else { return }
            if password == nil {
                KeychainWrapper.standard.set(text, forKey: "Password")
                self.loadDataFromUserDefaults()
                
            } else if password == text {
                self.loadDataFromUserDefaults()

            } else {
                let ac = UIAlertController(title: "User Authentication Failed", message: "You could not be identified.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        }))
        
        present(ac, animated: true)
    }
    
    
    fileprivate func loadDataFromUserDefaults() {
        //Load saved data from UD
        let defaults = UserDefaults.standard
        
        if let savedPeople = defaults.object(forKey: "people") as? Data {
            let jsonDecoder = JSONDecoder()
            
            do {
                people = try jsonDecoder.decode([Person].self, from: savedPeople)
            } catch {
                print("Could not decode")
            }
        }
        self.collectionView.reloadData()
    }

    
    //MARK: - Image Picker Delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        //creates a unique name string for the image name and appends to image
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        //Write image to disk as jpeg
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        // create new person
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        save()
        collectionView.reloadData()
        
        //Dismisses the top-most view controller
        dismiss(animated: true)
    }
    
    
    
    // Create image picker
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    
    //MARK: - Private Methods

    
    func getDocumentsDirectory() -> URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return path[0]
    }

    
    @objc func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(people) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "people")
        } else {
            print("Unable to save data")
        }
    }
    
    
    //MARK: - Collection View Delegate / Data Source

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            fatalError("Unable to dequeue Person Cell")
        }
        
        let person = people[indexPath.item]
        cell.name.text = person.name
        
        let path = getDocumentsDirectory().appendingPathComponent(person.image)
        cell.imageView.image = UIImage(contentsOfFile: path.path)
        
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        let choiceAC = UIAlertController(title: "Rename Or Delete Person", message: nil, preferredStyle: .alert)
        choiceAC.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.people.remove(at: indexPath.item)
            self?.collectionView.reloadData()
        }))
        choiceAC.addAction(UIAlertAction(title: "Rename", style: .default, handler: { [weak self] _ in
            
            let ac = UIAlertController(title: "Rename Person", message: nil, preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak ac] _ in
                //Attempt to read textfields text
                guard let newName = ac?.textFields?[0].text else { return }
                person.name = newName
                self?.save()
                self?.collectionView.reloadData()
            }))
            
            self?.present(ac, animated: true)
        }))
        
        present(choiceAC, animated: true)

    }
}

